# frozen_string_literal: true

module ModelConcerns::Session::HasTwitterFeed
  extend ActiveSupport::Concern

  included do
    validate :presense_of_all_twitter_related_fields, if: :any_of_them_is_set?
  end

  private

  def any_of_them_is_set?
    !twitter_feed_href.nil? || !twitter_feed_widget_id.nil? || !twitter_feed_title.nil?
  end

  def presense_of_all_twitter_related_fields
    errors.add(:twitter_feed_href, :blank) if twitter_feed_href.blank?
    errors.add(:twitter_feed_widget_id, :blank) if twitter_feed_widget_id.blank?
    errors.add(:twitter_feed_title, :blank) if twitter_feed_title.blank?
  end
end
