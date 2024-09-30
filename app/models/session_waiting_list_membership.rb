# frozen_string_literal: true
class SessionWaitingListMembership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :session_waiting_list
  belongs_to :user, touch: true

  validates :user, :session_waiting_list, presence: true
  validates :user_id, uniqueness: { scope: :session_waiting_list_id }

  acts_as_list scope: :session_waiting_list
end
