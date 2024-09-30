# frozen_string_literal: true

module ModelConcerns
  module Session
    module HasImmersiveDeliveryMethods
      extend ActiveSupport::Concern

      included do
        validate :max_number_of_immersive_participants_is_greater, if: proc { |s|
                                                                         s.immersive_type == self.class.const_get('ImmersiveTypes::GROUP')
                                                                       }

        validate :immersive_costs_satisfies_system_parameters, if: proc { |s| !s.immersive_free }
      end

      def can_change_immersive_free_slots?
        return true unless persisted? # new, unsaved session

        !started? && !finished?
      end

      def can_change_livestream_free_slots?
        return true unless persisted? # new, unsaved session

        !started? && !finished?
      end

      def can_change_immersive_access_cost?
        return true unless persisted? # new, unsaved session
        return false if started?
        return false if active?
        return false if cancelled?

        # FIXME: BRAINTREE
        payment_transactions.immersive_access.success.blank?
      end

      def can_change_immersive_purchase_price?
        can_change_immersive_access_cost?
      end

      def max_interactive_participants_by_service_limit
        case service_type
        when 'zoom'
          max_number_of_zoom_participants
        when 'webrtcservice'
          max_number_of_webrtcservice_participants
        else
          0
        end
      end

      def max_interactive_participants_by_business_plan
        return max_interactive_participants_by_service_limit if organization.split_revenue?

        case service_type
        when 'zoom'
          max_number_of_zoom_participants
        when 'webrtcservice'
          max_number_of_webrtcservice_participants
        else
          organization.service_subscription_feature_value(:max_interactive_participants).to_i
        end
      end

      def max_interactive_participants
        [
          max_interactive_participants_by_service_limit,
          max_interactive_participants_by_business_plan
        ].min
      end

      private

      def max_number_of_immersive_participants_is_greater
        return unless ::Room::ServiceTypes::INTERACTIVE.include? service_type

        if max_number_of_immersive_participants.to_i > max_number_of_immersive_participants_with_sources.to_i
          errors.add(:max_number_of_immersive_participants,
                     "must be in less than #{max_number_of_immersive_participants_with_sources.to_i}")
        elsif max_number_of_immersive_participants.to_i > max_interactive_participants_by_service_limit.to_i
          errors.add(:max_number_of_immersive_participants,
                     I18n.t('models.session.errors.max_interactive_participants_service_limit', limit: max_interactive_participants_by_service_limit))
        elsif max_number_of_immersive_participants.to_i > max_interactive_participants_by_business_plan.to_i
          errors.add(:max_number_of_immersive_participants,
                     I18n.t('models.session.errors.max_interactive_participants_subscription_limit', limit: max_interactive_participants_by_business_plan))
        elsif max_number_of_immersive_participants.to_i < min_number_of_immersive_and_livestream_participants.to_i
          errors.add(:max_number_of_immersive_participants, 'must be in greater than minimum number')
        end
      end

      # NOTE: if you update this logic, keep livestream_costs_satisfies_system_parameters in sync
      def immersive_costs_satisfies_system_parameters
        update_by_admin = persisted? && !update_by_organizer
        return if update_by_admin

        return if !immersive_purchase_price_changed? && !duration_changed?

        if immersive_access_cost.present? && immersive_access_cost < immersive_min_access_cost
          errors.add(:immersive_access_cost, :greater_than_or_equal_to, count: immersive_min_access_cost)
        end

        # NOTE: accordingly to Alex we need to compare it with "base" immersive_purchase_price, not "total purchase price" here
        if immersive_type == self.class.const_get('ImmersiveTypes::GROUP')
          if immersive_access_cost.present? && immersive_access_cost > ::SystemParameter.max_group_immersive_session_access_cost
            errors.add(:immersive_access_cost, :less_than_or_equal_to,
                       count: ::SystemParameter.max_group_immersive_session_access_cost)
          end
        elsif immersive_type == self.class.const_get('ImmersiveTypes::ONE_ON_ONE')
          if immersive_access_cost.present? && immersive_access_cost > ::SystemParameter.max_one_on_one_immersive_session_access_cost
            errors.add(:immersive_access_cost, :less_than_or_equal_to,
                       count: ::SystemParameter.max_one_on_one_immersive_session_access_cost)
          end
        end
      end
    end
  end
end
