# frozen_string_literal: true
class SessionWaitingList < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :session

  has_many :session_waiting_list_memberships, dependent: :destroy
  has_many :users, through: :session_waiting_list_memberships, source: :user
  validates :session_id, uniqueness: true, if: ->(obj) { obj.session_id.present? }
end
