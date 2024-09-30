# frozen_string_literal: true
class SessionSetting < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
end
