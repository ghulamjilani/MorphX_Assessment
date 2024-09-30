# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::StripeDb::ServiceSubscriptionAbility do
  let(:ability) { described_class.new(current_user) }

  context 'when service subscriptions disabled' do
    describe '#edit' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :edit_by_business_plan, instance_double('service_subscriptions') }
    end
  end

  context 'when service subscriptions enabled' do
    let(:global_credentials) do
      global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
      global_credentials[:service_subscriptions][:enabled] = true
      global_credentials
    end

    before do
      allow(Rails.application.credentials).to receive(:global).and_return(global_credentials)
    end

    describe '#edit' do
      let(:current_user) { create(:user) }
      let(:subscription) { create(:stripe_service_subscription, user: current_user) }

      it { expect(ability).to be_able_to :edit_by_business_plan, subscription }
      it { expect(ability).not_to be_able_to :edit_by_business_plan, instance_double('stripe_service_subscription') }
    end
  end
end
