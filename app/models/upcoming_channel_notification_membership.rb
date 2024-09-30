# frozen_string_literal: true
class UpcomingChannelNotificationMembership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :channel
  belongs_to :user, touch: true

  validates :user_id, uniqueness: { scope: :channel_id }
end
