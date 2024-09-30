# frozen_string_literal: true

module AbilityLib
  module Partner
    class PlanAbility < AbilityLib::Partner::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          edit: [::Partner::Plan]
        }
      end

      def load_permissions
        return unless user.persisted?
      end
    end
  end
end
