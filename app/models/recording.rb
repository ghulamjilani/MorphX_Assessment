# frozen_string_literal: true
class Recording < ActiveRecord::Base
  enum status: {
    found: 0,
    ready_to_tr: 1,
    transcoding: 2,
    done: 3,
    error: 4,
    transcoded: 5
  }

  def processing?
    %w[ready_to_tr transcoding transcoded].include? status.to_s
  end

  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::Shared::RatyRate
  include ModelConcerns::HasShortUrl
  include Rails.application.routes.url_helpers
  include ModelConcerns::ActiveModel::Extensions

  include ModelConcerns::Recording::PgSearchable
  include ModelConcerns::Trackable
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Shared::Transcodable
  include ModelConcerns::Shared::HasHlsPaths
  include ModelConcerns::Shared::HasStorageRecords
  include ModelConcerns::Shared::HasLists
  include ModelConcerns::Shared::Blockable
  include ModelConcerns::Shared::ActsAsWishlistItem

  acts_as_votable # for likes
  acts_as_ordered_taggable_on :tags

  module RateKeys
    QUALITY_OF_CONTENT = 'quality_of_content'
    VIDEO_QUALITY = 'video_quality'
    SOUND_QUALITY = 'sound_quality'

    ALL = [
      QUALITY_OF_CONTENT,
      VIDEO_QUALITY,
      SOUND_QUALITY
    ].freeze

    MANDATORY = [
      QUALITY_OF_CONTENT
    ].freeze
  end

  ratyrate_rateable(*::Recording::RateKeys::ALL)

  SHARE_IMAGE_WIDTH = 1280
  SHARE_IMAGE_HEIGHT = 720

  belongs_to :channel
  has_one :organization, through: :channel

  has_many :payment_transactions, as: :purchased_item, dependent: :destroy
  has_many :system_credit_entries, as: :commercial_document, dependent: :destroy
  has_many :log_transactions, as: :abstract_session, dependent: :destroy
  has_many :recording_members, dependent: :destroy, autosave: true
  has_many :recording_participants, through: :recording_members, source: :participant
  has_many :reviews, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :polls, class_name: 'Poll::Poll', as: :model, dependent: :destroy
  has_one :recording_image, dependent: :destroy
  has_one_attached :file

  accepts_nested_attributes_for :recording_image, allow_destroy: true

  before_validation :sanitize_description, if: :description_changed?
  # validates :provider, :vid, presence: true, :title
  validates :channel_id, presence: true
  validates :purchase_price, allow_nil: true, numericality: { greater_than: -1, less_than: 1_000_000 }
  validate :file_validation, on: :create

  delegate :show_comments, to: :channel
  delegate :show_reviews, to: :channel
  delegate :id, to: :organization, prefix: true, allow_nil: false

  after_create :update_short_urls
  after_commit :video_analyzer, on: :create
  after_commit :check_storage_records, if: proc { |recording| recording.instance_variable_get(:@_new_record_before_last_commit) || recording.saved_change_to_status? }

  def user
    channel.organizer
  end

  def file_validation
    return true if Rails.env.test?

    if file.attached?
      if file.blob.byte_size > 40_000_000_000
        errors.add(:file, value: 'Too big')
        file.purge
      elsif !file.blob.content_type.starts_with?('video/')
        errors.add(:file, value: 'Wrong video format')
        file.purge
      elsif file.blob.metadata['duration'].to_i > 28_800
        errors.add(:file, value: 'Too long')
        file.purge
      end
    else
      errors.add(:file, value: 'Blank')
    end
  end

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :available, -> { not_deleted.where(status: :done) }
  scope :visible, lambda {
    joins(:channel)
      .joins('LEFT JOIN organizations ON organizations.id = channels.organization_id')
      .joins('LEFT JOIN presenters ON presenters.id = channels.presenter_id')
      .joins('LEFT JOIN users ON users.id = presenters.user_id OR users.id = organizations.user_id')
      .where.not(channels: { listed_at: nil })
      .where.not(published: nil).where(hide: false, private: false, channels: { status: :approved, archived_at: nil,
                                                                                fake: false }, users: { fake: false })
      .where(deleted_at: nil)
  }

  scope :processing, -> { where(status: %i[ready_to_tr transcoding transcoded]) }

  scope :published, -> { where.not(published: nil) }
  scope :not_published, -> { where(published: nil) }

  def self.for_homepage
    visible.where(show_on_home: true)
  end

  def as_json(_options = {})
    {
      id: id,
      title: title,
      hide: hide,
      private: private,
      shares_count: shares_count,
      channel_id: channel_id,
      list_id: lists.first&.id,
      views_count: views_count,
      thumbnail_url: poster_url,
      rating: rating,
      preview_share_relative_path: preview_share_relative_path,
      purchase_price: purchase_price.to_f,
      is_published: !!published,
      not_processing: done?
    }
  end

  def visible?
    !hide?
  end

  def rating
    average ? average.avg : 0
  end

  def publish!
    if done?
      update_attribute(:published, Time.now)
    else
      ready_to_tr!
      update_attribute(:published, Time.now)
    end
  end

  def unpublish!
    update_attribute(:published, nil)
  end

  def published?
    !!published
  end

  def likes_cache_key
    "likes/#{self.class.to_s.downcase}/#{id}"
  end

  def likes_count
    Rails.cache.fetch(likes_cache_key) { get_likes.count }
  end

  def toggle_like_relative_path
    channel.relative_path + "/toggle_like?recording_id=#{id}"
  end

  def organizer
    channel&.organizer
  end

  def url
    if hls_main
      "https://#{ENV['HWCDN']}#{hls_main}"
    elsif Rails.env.development?
      '/stub/stream.mp4'
    end
  end

  def preview_url
    if hls_preview
      "https://#{ENV['HWCDN']}#{hls_preview}"
    elsif Rails.env.development?
      '/stub/preview_stream.mp4'
    end
  end

  def image_by_size(size)
    "https://#{ENV['HWCDN']}#{hls_preview_path}images/#{main_image_number}/#{size.delete('x')}.jpg"
  end

  def poster_url
    if recording_image&.image&.player&.url
      recording_image.image.player.url
    elsif hls_main
      image_by_size('410x230')
    elsif Rails.env.development?
      "/stub/jpgs/#{id.to_s[-1]}.jpg"
    end
  end

  alias_method :share_image_url, :poster_url

  # def video_url
  #   "https://drive.google.com/uc?export=download&id=#{vid}"
  # end
  #
  # def thumbnail_origin_url
  #   "https://drive.google.com/thumbnail?authuser=0&sz=w1280&id=#{vid}"
  # end
  #
  # def main_filename
  #   attributes['thumbnail']
  # end
  #
  # def embed_url
  #   url_for(file)
  #   # begin
  #   #   raw_data = JSON.parse(raw)
  #   #   url = raw_data['embedUrl']
  #   #
  #   #   url = if raw_data['embedUrl'].start_with?('https://drive.google.com')
  #   #           raw_data['embedUrl']
  #   #         elsif raw_data['url'].start_with?('https://drive.google.com')
  #   #           raw_data['url']
  #   #         end
  #   #   raise('No embedUrl') unless url
  #   #   uri = URI.parse(url)
  #   #   path = uri.path
  #   #   if path.split('/').last != 'preview'
  #   #     arr = path.split('/')
  #   #     arr[arr.size - 1] = 'preview'
  #   #     uri.path = arr.join('/')
  #   #   end
  #   #   uri.to_s
  #   # rescue => e
  #   #   "https://drive.google.com/file/d/#{vid}/preview?usp=drive_web"
  #   # end
  # end

  def pinterest_share_preview_image_url
    ActionController::Base.helpers.asset_url(poster_url)
  end

  def always_present_description
    description.presence || channel.description
  end

  def always_present_description_text
    @always_present_description_text ||= Nokogiri::HTML.parse(always_present_description).inner_text
  end

  def description_text
    @description_text ||= Nokogiri::HTML.parse(description).inner_text
  end

  def share_title
    I18n.t('models.recording.share_title', organizer_display_name: organizer.public_display_name,
                                           title: always_present_title)
  end

  def share_description
    always_present_description_text
  end

  # utm_params are needed for tracking visits from email links
  # @see UTM dependency
  # refc_user for sharing
  # @see SharingHelper, SharedControllerHelper
  def absolute_path(utm_params = nil, refc_user = nil)
    result = channel.absolute_path
    params = ["recording_id=#{id}"]
    params << utm_params if utm_params
    params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
    result += "?#{params.join('&')}"
    result
  end

  def relative_path
    channel.relative_path + "?recording_id=#{id}"
  end

  def preview_share_relative_path
    "#{channel.relative_path}/preview_share?recording_id=#{id}"
  end

  def always_present_title
    title.presence || channel.always_present_title
  end

  def service_fee
    0.0
  end

  def free?
    purchase_price.to_f.zero?
  end

  def duration_in_minutes
    duration.to_i / 1000 / 60 if duration.present? && duration.to_i.positive?
  end

  def actual_duration
    cropped_duration.to_i.zero? ? duration.to_i : cropped_duration
  end

  def is_fake?
    fake? || channel&.is_fake?
  end

  def s3_root_path
    "/#{channel.organizer_user_id}/channels/#{channel_id}"
  end

  def sanitize_description
    self.description = Sanitize.clean(description.to_s.html_safe, elements: %w[a b i br s u ul ol li p strong em],
                                                                  attributes: { a: %w[href target title] }.with_indifferent_access)
  end

  def update_comments_count
    return 0 if destroyed?

    count = comments.count
    update_attribute(:comments_count, count)
    count
  end

  def unique_view_group_start_at
    Time.now.utc.beginning_of_hour
  end

  private

  def check_storage_records
    RecordingJobs::VodStorage::CheckStorageRecordsJob.perform_async(id)
  end

  def video_analyzer
    RecordingJobs::RefreshMetadataJob.perform_async(id)
  end
end
