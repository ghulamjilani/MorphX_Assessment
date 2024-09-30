# frozen_string_literal: true
class Rate < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :rater, class_name: 'User'
  belongs_to :rateable, polymorphic: true

  module RateKeys
    QUALITY_OF_CONTENT    = 'quality_of_content'
    PRESENTER_PERFORMANCE = 'presenter_performance'
    VIDEO_QUALITY = 'video_quality'
    SOUND_QUALITY = 'sound_quality'
    IMMERSS_EXPERIENCE = 'immerss_experience'

    ALL = [
      QUALITY_OF_CONTENT,
      PRESENTER_PERFORMANCE,
      VIDEO_QUALITY,
      SOUND_QUALITY,
      IMMERSS_EXPERIENCE
    ].freeze
  end

  after_create do
    if Session::RateKeys::MANDATORY.include?(dimension.to_s)
      Rails.cache.delete(session.organizer.reviews_with_comment_cache_key)
      Rails.cache.delete(session.channel.reviews_with_comment_cache_key)
    end
  end

  after_update do
    if Session::RateKeys::MANDATORY.include?(dimension.to_s)
      Rails.cache.delete(session.organizer.reviews_with_comment_cache_key)
      Rails.cache.delete(session.channel.reviews_with_comment_cache_key)
    end
  end

  validate :rating_ability

  private

  def session
    rateable
  end

  def rating_ability
    return unless rateable.is_a?(Session)

    if rateable.room_members.banned.exists?(abstract_user: rater)
      errors.add(:rateable,
                 'You have been banned from this session')
    end
  end
end
