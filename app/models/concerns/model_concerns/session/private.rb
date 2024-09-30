# frozen_string_literal: true

module ModelConcerns::Session::Private
  extend ActiveSupport::Concern

  included do
    before_validation :private_validation
  end

  private

  def private_validation
    if private? && Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
      return true if channel.organization.split_revenue_plan
      return false if channel.organization.user.service_subscription.blank?

      !channel.organization.user.service_subscription.plan_package&.is_private_session_available?.nil?
    else
      true
    end
  end
end
