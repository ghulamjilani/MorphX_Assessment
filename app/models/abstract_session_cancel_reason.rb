# frozen_string_literal: true
class AbstractSessionCancelReason < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :name, presence: true, uniqueness: true
end
