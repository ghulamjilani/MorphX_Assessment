# frozen_string_literal: true
class UserLog < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  ACTIONS = %w[create_session update_session cancel_session].freeze
  belongs_to :user
  belongs_to :item, polymorphic: true
end
