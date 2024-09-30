# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ChannelSubscriptionsController do
  let(:current_user) { create(:stripe_user_with_card) }
  let!(:stripe_db_subscription) { create(:stripe_db_subscription, user: current_user) }
  let!(:stripe_db_plan) { create(:stripe_db_plan) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include stripe_db_subscription.stripe_plan.stripe_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when given id param' do
        before do
          get :show, params: { id: stripe_db_subscription.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include stripe_db_subscription.stripe_plan.stripe_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      context 'when given gift param' do
        before do
          post :create, params: { plan_id: stripe_db_plan.id, gift: '1',
                                  recipient: Forgery('internet').email_address,
                                  stripe_token: current_user.default_credit_card.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include stripe_db_plan.stripe_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST check_recipient_email:' do
      context 'when given email param' do
        before do
          post :check_recipient_email, params: { id: stripe_db_plan.channel_subscription.id, email: 'ololo@lo.com' },
                                       format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include 'ololo@lo.com' }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
