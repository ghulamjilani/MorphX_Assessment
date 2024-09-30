# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::HasServiceSubscription do
  let(:stripe_service_subscription) { create(:stripe_service_subscription) }
  let(:user) { stripe_service_subscription.user }

  describe '#service_subscription' do
    it { expect { user.service_subscription }.not_to raise_error }

    it { expect(user.service_subscription).to be_present }
  end

  describe '#service_subscription_feature_value' do
    let(:feature_parameter) do
      create(:feature_parameter,
             plan_package: stripe_service_subscription.plan_package,
             plan_feature: create(:manage_creators_plan_feature), value: true)
    end
    let(:code) { feature_parameter.plan_feature.code }

    it { expect { user.service_subscription_feature_value(code) }.not_to raise_error }

    it { expect(user.service_subscription_feature_value(code)).to be_present }
  end
end
