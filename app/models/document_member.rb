# frozen_string_literal: true
class DocumentMember < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user, touch: true
  belongs_to :document, touch: true
  belongs_to :payment_transaction

  validates :user_id, uniqueness: { scope: :document }
end
