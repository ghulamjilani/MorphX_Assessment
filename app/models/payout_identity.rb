# frozen_string_literal: true
class PayoutIdentity < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :payout_method
end
