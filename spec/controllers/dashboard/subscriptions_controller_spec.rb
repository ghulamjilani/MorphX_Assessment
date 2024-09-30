# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::SubscriptionsController do
  before { sign_in current_user, scope: :user }

  let(:channel) { create(:listed_channel) }
  let(:current_user) { channel.organizer }

  describe 'POST :create ->' do
    let(:interval_count) { [1, 3, 6, 12].sample }
    let(:params) do
      {
        subscription: {
          channel_id: channel.id,
          description: Forgery(:lorem_ipsum).words(10),
          enabled: '1',
          plans_attributes: {
            '0': {
              im_name: "#{channel.always_present_title} plan #{(0..999).to_a.sample}",
              im_color: "##{SecureRandom.hex(3)}",
              im_replays: '1',
              im_enabled: '1',
              interval: 'month',
              interval_count: interval_count,
              amount: rand(999) / 100.0 * interval_count,
              autorenew: '1',
              trial_period_days: (0..7).to_a.sample
            }
          }
        }
      }
    end

    render_views

    it 'creates new subscription' do
      expect do
        post :create, params: params, format: :html
        expect(response).to be_redirect
      end.to change(Subscription, :count).by(1)
                                         .and change { StripeDb::Plan.count }.by(1)
    end
  end
end
