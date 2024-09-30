# frozen_string_literal: true

module AbilityLib
  module MarketingTools
    class OptInModalAbility < AbilityLib::MarketingTools::Base
      def service_admin_abilities
        @service_admin_abilities ||= {}
      end

      def load_permissions
        return unless user.persisted?

        if user.organization.present?
          can %i[create edit destroy], ::MarketingTools::OptInModal
        end
      end
    end
  end
end
