# frozen_string_literal: true
class LinkPreview < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  module Statuses
    NEW   = 'new'
    ERROR = 'error'
    DONE  = 'done'
    RETRY = 'retry'

    ALL = [NEW, RETRY, ERROR, DONE].freeze
  end

  validates :url, presence: true # use find_or_create_by!(url:)
  validate :sanitize_url, if: :url_changed?
  validate :minimum_required_data

  validates :status, presence: true, inclusion: { in: Statuses::ALL }
  validates_with UrlFormatValidator

  after_commit :run_crawler, on: :create

  Statuses::ALL.each do |const|
    define_method("status_#{const}?") { status == const }
    define_method("status_#{const}!") { update_attribute(:status, const) }
  end

  def days_outdate_interval
    (Rails.application.credentials.backend.dig(:initialize, :link_preview, :days_outdate_interval) || 14).to_i
  end

  def schedule_link_parse
    LinkPreviewJobs::ParseJob.perform_async(id)
  end

  def outdated?
    updated_at.to_i < (Time.now - days_outdate_interval.days).to_i
  end

  def run_crawler(try_count = 0)
    if Rails.env.test?
      update(
        title: Forgery(:lorem_ipsum).words(5, random: true),
        description: Forgery(:lorem_ipsum).words(15, random: true),
        status: Statuses::DONE
      )
      return
    end

    crawlers = [Sales::Parsers::Facebook, Sales::Parsers::Custom]
    threads = []
    results = []

    crawlers.each { |p| threads << Thread.new { p.new(url: url).fetch } }
    threads.each { |t| results << t.value }
    results.reject!(&:blank?)
    parsed = results.first
    (results - [parsed]).each do |data|
      parsed.title = data.title if parsed.title.blank?
      parsed.description = data.description if parsed.description.blank?
      parsed.short_description = data.short_description if parsed.short_description.blank?
      parsed.images = [parsed.images.to_a, data.images.to_a].flatten.compact.uniq
    end

    if parsed.blank? || (parsed.title.blank? && parsed.short_description.blank?)
      LinkPreviewsChannel.broadcast_to(self, event: 'link_parse_failed', data: {})
      LinkPreviewsChannel.broadcast 'link_parse_failed', { id: id, url: url }

      status_error! and return unless try_count.zero?

      status_retry!
      LinkPreviewJobs::ParseJob.perform_at(20.seconds.from_now, id, try_count + 1)
      return
    end

    mapped = {
      title: parsed.title,
      description: parsed.short_description,
      image_url: parsed.images&.first
    }

    self.attributes = mapped
    self.status = LinkPreview::Statuses::DONE
    save!
    mapped.merge!(attributes.slice(:id, :url, :status, :title, :description, :image_url))
    LinkPreviewsChannel.broadcast_to(self, event: 'link_parsed', data: mapped)
    LinkPreviewsChannel.broadcast 'link_parsed', mapped
  rescue StandardError => e
    Airbrake.notify("LinkPreview:run_crawler failed #{e.message}", parameters: { id: id })
  end

  private

  def sanitize_url
    self.url = SanitizeUrl.sanitize_url(url)
    errors.add(:url, 'does not look like valid URL') if url.blank?
  end

  def minimum_required_data
    return unless status_done?

    if title.blank? && description.blank?
      self.status = Statuses::ERROR
      errors.add(:title, 'Title or description must be present')
    end
  end
end
