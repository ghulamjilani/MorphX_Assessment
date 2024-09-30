# frozen_string_literal: true

module ModelConcerns
  module User
    module UsesSignupTokens
      extend ActiveSupport::Concern

      included do
        has_many :signup_tokens, dependent: :destroy
      end

      def can_use_wizard?
        return false unless persisted?
        return false if AbilityLib::UserAbility.new(self).cannot?(:become_a_creator, self)

        Rails.application.credentials.global.dig(:wizard, :enabled).present? || can_use_wizard.present?
      end

      def can_use_wizard!
        update(can_use_wizard: true)
      end

      def cannot_buy_subscription!
        update(can_buy_subscription: false)
      end
    end
  end
end
