# frozen_string_literal: true

module ModelConcerns
  module Organization
    module HasServiceSubscription
      extend ActiveSupport::Concern

      delegate :service_subscription, to: :user

      delegate :service_subscription_feature_value, to: :user
    end
  end
end
