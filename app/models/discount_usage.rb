# frozen_string_literal: true
class DiscountUsage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :discount
  belongs_to :user
end
