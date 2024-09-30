# frozen_string_literal: true
class IssuedSystemCredit < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # disable STI
  self.inheritance_column = :_type_disabled

  module Statuses
    OPEN    = 'open'
    EXPIRED = 'expired'
  end

  module Types
    BOO_BOO_CREDIT  = 'boo_boo_credit'
    CHOSEN_REFUND   = 'chosen_refund'
    TODO_COMPLETING = 'todo_completing'

    ALL = [
      BOO_BOO_CREDIT,
      CHOSEN_REFUND,
      TODO_COMPLETING
    ].freeze
  end

  scope :status_open, lambda {
                        where('status = ?', Statuses::OPEN)
                      } # Creating scope :open. Overwriting existing method IssuedSystemCredit.open.
  scope :expired, -> { where('status = ?', Statuses::EXPIRED) }

  belongs_to :participant, touch: true

  validates :status, inclusion: { in: [Statuses::OPEN, Statuses::EXPIRED] }

  # NOTE: if you want to rename type make sure you saw that commit
  #      https://github.com/alexwilner/immerss_migrations/commit/892c0e3e0dc54d9db5f3e6ace28f07822c032ac2
  validates :type, inclusion: { in: Types::ALL }

  validates :amount, numericality: { greater_than: 0 }

  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status = Statuses::OPEN if status.blank?
  end
end
