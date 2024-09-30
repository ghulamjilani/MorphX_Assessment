# frozen_string_literal: true
class IssuedPresenterCredit < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # disable STI
  self.inheritance_column = :_type_disabled

  module Types
    EARNED_CREDIT = 'earned_credit'
    REFERRAL_FEE = 'referral_fee'
    REPLENISHMENT = 'replenishment'

    ALL = [
      EARNED_CREDIT,
      REFERRAL_FEE,
      REPLENISHMENT
    ].freeze
  end

  belongs_to :presenter, touch: true

  validates :type, inclusion: { in: Types::ALL }
end
