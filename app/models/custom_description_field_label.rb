# frozen_string_literal: true
class CustomDescriptionFieldLabel < ActiveRecord::Base
  includes ActiveModel::ForbiddenAttributesProtection

  validates :description, presence: true, uniqueness: true
end
