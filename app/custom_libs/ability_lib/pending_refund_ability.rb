# frozen_string_literal: true

module AbilityLib
  class PendingRefundAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      can :reimburse_refund, PendingRefund do |pending_refund|
        lambda do
          return false unless pending_refund.user == user

          session = pending_refund.abstract_session

          # because cancelled sessions doesn't have rooms
          session.cancelled? || !session.room_members.exists?(abstract_user: user, joined: true)
        end.call
      end
    end
  end
end
