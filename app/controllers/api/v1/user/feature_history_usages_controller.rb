# frozen_string_literal: true

module Api
  module V1
    module User
      class FeatureHistoryUsagesController < Api::V1::User::ApplicationController
        def index
          raise(AccessForbiddenError) unless can?(:view_billing_report, current_user.current_organization)

          query = ::FeatureHistoryUsage.joins(feature_usage: :plan_feature)
                                       .where(feature_usages: { organization_id: current_user.current_organization_id })

          if params[:created_at_from].present? || params[:created_at_to].present?
            from = params[:created_at_from].respond_to?(:to_datetime) ? params[:created_at_from].to_datetime : nil
            to = params[:created_at_to].respond_to?(:to_datetime) ? params[:created_at_to].to_datetime : nil

            if from.present? && to.present?
              query = query.where(feature_history_usages: { created_at: from..to })
            elsif from.present?
              query = query.where('feature_history_usages.created_at >= :from', from: from)
            elsif to.present?
              query = query.where('feature_history_usages.created_at <= :to', to: to)
            end
          end

          query = query.where(plan_features: { code: params[:code] }) if params[:code].present?
          query = query.where(feature_usages: { plan_feature_id: params[:plan_feature_id] }) if params[:plan_feature_id].present?
          query = query.where(feature_history_usages: { feature_usage_id: params[:feature_usage_id] }) if params[:feature_usage_id].present?
          if params[:model_id].present? && params[:model_type].present?
            query = query.where(feature_history_usages: { model_id: params[:model_id], model_type: params[:model_type] })
          end

          @feature_history_usages = query.order('feature_history_usages.created_at DESC').limit(@limit).offset(@offset).preload(:plan_feature, :feature_usage)
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
