# frozen_string_literal: true
class FoundUsMethod < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :description, presence: true
  validates :description, uniqueness: true
  has_many :user_accounts
end
