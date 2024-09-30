# frozen_string_literal: true
class Review < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ActsAsCommentable::Comment
  include ModelConcerns::ActiveModel::Extensions

  # disable STI
  self.inheritance_column = :_type_disabled

  # NOTE: Comments belong to a user
  belongs_to :user, optional: false
  belongs_to :commentable, polymorphic: true, optional: false

  default_scope -> { order('reviews.created_at ASC') }

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  # acts_as_voteable

  validates :user, presence: true
  validates :overall_experience_comment, presence: true # the other comment is optional
  validate :rating_ability
  validate :rating_presence

  validates :user, uniqueness: { scope: :commentable }

  scope :visible, -> { where(visible: true) }
  scope :not_visible, -> { where(visible: true) }
  scope :hidden, -> { where.not(visible: true) }
  scope :not_hidden, -> { where(visible: true) }
  scope :with_rates_joined, lambda {
    joins("LEFT JOIN sessions ON reviews.commentable_type = 'Session' AND reviews.commentable_id = sessions.id")
      .joins("LEFT JOIN recordings ON reviews.commentable_type = 'Recording' AND reviews.commentable_id = recordings.id")
      .joins("LEFT JOIN rates ON (rates.rateable_type = 'Session' AND rates.rateable_id = sessions.id AND rates.rater_id = reviews.user_id) OR (rates.rateable_type = 'Recording' AND rates.rateable_id = recordings.id AND rates.rater_id = reviews.user_id)")
      .where.not(rates: { dimension: nil })
  }
  scope :from_participants, lambda {
    with_rates_joined.where(rates: { dimension: Rate::RateKeys::QUALITY_OF_CONTENT })
  }
  scope :from_presenters, lambda {
    with_rates_joined.where(rates: { dimension: Rate::RateKeys::IMMERSS_EXPERIENCE })
  }
  scope :visible_for_user, lambda { |user|
    query = where(nil)
    query = if !user.is_a?(User) || !user.persisted?
              query.visible.from_participants
            elsif user.service_admin? || user.platform_owner?
              query.with_rates_joined
            elsif (channels_with_credentials = user.all_channels_with_credentials([:moderate_comments_and_reviews]).pluck(:id)).present?
              query.with_rates_joined.where(%{reviews.visible IS TRUE AND rates.dimension = :quality_of_content OR sessions.channel_id IN (:channel_ids) OR recordings.channel_id IN (:channel_ids)}, quality_of_content: Rate::RateKeys::QUALITY_OF_CONTENT, user_id: user.id, channel_ids: channels_with_credentials)
            else
              query.from_participants.where(%(reviews.visible IS TRUE), user_id: user.id)
            end
    query
  }

  after_create do
    Rails.cache.delete(session.organizer.reviews_with_comment_cache_key)
    Rails.cache.delete(session.channel.reviews_with_comment_cache_key)
  end

  after_update do
    Rails.cache.delete(session.organizer.reviews_with_comment_cache_key)
    Rails.cache.delete(session.channel.reviews_with_comment_cache_key)
  end

  def rate_info(dimension = 'quality_of_content')
    Rate.find_by(rater: user, rateable: commentable, dimension: dimension)
  end

  def visible!
    update(visible: true)
  end

  def hidden!
    update(visible: false)
  end

  private

  def session
    commentable
  end

  def rating_presence
    case commentable.class.to_s
    when 'Session', 'Recording'
      raise I18n.t('models.review.errors.rating_required') if user != commentable.organizer && !commentable.rates(::Rate::RateKeys::QUALITY_OF_CONTENT).exists?(rater_id: user.id)
    end
  end

  def rating_ability
    unless %w[
      Session Recording
    ].include?(commentable.class.to_s)
      errors.add(:commentable,
                 I18n.t('models.review.errors.unsupported_reviewable', reviewable_type: commentable_type))
    end
    if ::AbilityLib::SessionAbility.new(user).merge(::AbilityLib::RecordingAbility.new(user)).cannot?(
      :create_or_update_review_comment, commentable
    )
      errors.add(:commentable,
                 I18n.t('models.review.errors.not_allowed',
                        reviewable_type: commentable_type))
    end
  end
end
