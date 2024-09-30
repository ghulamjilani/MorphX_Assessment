# frozen_string_literal: true
class ReferralCode < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  has_many :referrals
end
