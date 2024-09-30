# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ServicePlansController do
  let!(:plan) { create(:service_plan_with_stripe_data) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when plan exsits' do
        before { get :show, params: { id: plan.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when plan does not exsit' do
        before { get :show, params: { id: -1 }, format: :json }

        it { expect(response).not_to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
