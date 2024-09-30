# frozen_string_literal: true
class AuthyRecord < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user

  module Statuses
    REGISTERED = 'registered'
    SENT       = 'sent'
    APPROVED   = 'approved'

    ALL = [REGISTERED, SENT, APPROVED].freeze
  end

  after_initialize :set_initial_status
  def set_initial_status
    self.status ||= Statuses::REGISTERED
  end

  validates :status, inclusion: { in: Statuses::ALL }

  after_destroy do
    response = Authy::API.delete_user(id: authy_user_id)
    Rails.logger.info response.inspect
  end
end
