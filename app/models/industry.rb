# frozen_string_literal: true
class Industry < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  validates :description, presence: true
  validates :description, uniqueness: true

  has_many :organizations
end
