# frozen_string_literal: true

module Api
  module V1
    module User
      class FeatureUsagesController < Api::V1::User::ApplicationController
        def index
          raise(AccessForbiddenError) if cannot?(:view_billing_report, current_user.current_organization)

          query = ::FeatureUsage.joins(:plan_feature)
                                .where(organization_id: current_user.current_organization_id)

          query = query.where(feature_usages: { plan_feature_id: params[:plan_feature_id] }) if params[:plan_feature_id].present?
          query = query.where(plan_features: { code: params[:code] }) if params[:code].present?

          @feature_usages = query.order('feature_usages.created_at DESC').limit(@limit).offset(@offset).preload(:plan_feature)
          @count = query.count
        end

        private

        def current_ability
          @current_ability ||= ::AbilityLib::OrganizationAbility.new(current_user)
        end
      end
    end
  end
end
