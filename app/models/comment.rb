# frozen_string_literal: true
class Comment < ActiveRecord::Base
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  has_many :comments, as: :commentable, dependent: :destroy

  scope :visible, -> { where(visible: true) }
  scope :visible_for_user, lambda { |user|
    query = joins("LEFT JOIN sessions ON comments.commentable_type = 'Session' AND comments.commentable_id = sessions.id")
            .joins("LEFT JOIN recordings ON comments.commentable_type = 'Recording' AND comments.commentable_id = recordings.id")
    if user&.service_admin? || user&.platform_owner?
      query
    elsif user && (channels_with_credentials = user.all_channels_with_credentials([:moderate_comments_and_reviews]).pluck(:id)).present?
      query.where(%{visible IS TRUE OR comments.user_id = :user_id OR sessions.channel_id IN (:channel_ids) OR recordings.channel_id IN (:channel_ids)}, user_id: user.id, channel_ids: channels_with_credentials)
    else
      query.visible
    end
  }

  before_validation :wrap_body_urls

  after_commit on: :create do
    commentable.update_comments_count if commentable.present?
  end

  def update_comments_count
    return 0 if destroyed?

    count = comments.count
    update_attribute(:comments_count, count)
    count
  end

  private

  def wrap_body_urls
    self.body = Html::Parser.new(body).wrap_urls.to_s
  end
end
