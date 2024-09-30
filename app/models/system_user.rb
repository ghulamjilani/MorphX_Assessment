# frozen_string_literal: true
class SystemUser < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
end
