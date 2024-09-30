# frozen_string_literal: true
class LayoutCustomCode < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  enum layout_position: {
    head_start: 0,
    head_end: 1,
    body_start: 2,
    body_end: 3
  }

  before_validation :sanitize_content, if: :content_changed?

  validates :content, presence: true
  validates :layout_position, presence: true, inclusion: { in: layout_positions }

  scope :enabled, -> { where(enabled: true) }

  def sanitize_content
    self.content = Nokogiri::HTML.fragment(content).to_html
  end

  def enable!
    update(enabled: true)
  end

  def disable!
    update(enabled: false)
  end
end
