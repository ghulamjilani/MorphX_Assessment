# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::PlanPackagesController do
  let(:plan_packages) do
    create(:plan_package,
           {
             name: 'Premium',
             description: 'Grow your business',
             position: 3,
             recommended: true,
             plans_attributes: [
               {
                 active: true,
                 amount: 24_999,
                 currency: 'usd',
                 interval: 'month',
                 interval_count: 1,
                 nickname: 'Premium Month',
                 trial_period_days: 7
               },
               {
                 active: true,
                 amount: 269_999,
                 currency: 'usd',
                 interval: 'year',
                 interval_count: 1,
                 nickname: 'Premium Annual',
                 trial_period_days: 7
               }
             ]
           })
  end

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when plan package exsits' do
        before { get :index, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
