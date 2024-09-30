# frozen_string_literal: true

module AbilityLib
  module PageBuilder
    class SystemTemplateAbility < AbilityLib::PageBuilder::Base
      def service_admin_abilities
        @service_admin_abilities ||= {}
      end

      def load_permissions
        return unless user.persisted?

        if user.platform_owner?
          can %i[create edit destroy], ::PageBuilder::SystemTemplate
        end
      end
    end
  end
end
