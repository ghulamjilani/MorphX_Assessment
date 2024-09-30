# frozen_string_literal: true
class PendingVodAvailabilityMembership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :abstract_session, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: %i[abstract_session_id abstract_session_type] }
end
