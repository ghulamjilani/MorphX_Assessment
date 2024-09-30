# frozen_string_literal: true
class TodoAchievement < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  BONUS_CREDIT_AMOUNT = 20.0

  module Types
    REFERRED_FIVE_FRIENDS    = 'Refer Five friends'
    SHARE_A_SESSION          = 'Share a Session'
    PARTICIPATE_IN_A_SESSION = 'Participate in a Session'
    REVIEW_A_SESSION         = 'Review a Session'

    ALL = [
      REFERRED_FIVE_FRIENDS,
      SHARE_A_SESSION,
      PARTICIPATE_IN_A_SESSION,
      REVIEW_A_SESSION
    ].freeze
  end

  # disable STI
  self.inheritance_column = :_type_disabled

  belongs_to :user, touch: true

  validates :type, uniqueness: { scope: [:user_id] }
  validates :type, inclusion: { in: Types::ALL }

  def self.all_checked_for?(user)
    Rails.cache.fetch("#{__method__}/#{user.cache_key}") do
      TodoAchievement.where(user: user).count == Types::ALL.size
    end
  end

  after_create :check_if_time_to_give_credit

  private

  def check_if_time_to_give_credit
    if self.class.all_checked_for?(user)
      user.receive_issued_system_credit!(amount: BONUS_CREDIT_AMOUNT,
                                         type: IssuedSystemCredit::Types::TODO_COMPLETING,
                                         status: IssuedSystemCredit::Statuses::OPEN)

      user.log_transactions.create!(type: LogTransaction::Types::TODO_COMPLETING,
                                    data: {},
                                    amount: BONUS_CREDIT_AMOUNT)
    end
  end
end
