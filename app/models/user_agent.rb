# frozen_string_literal: true
class UserAgent < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
end
