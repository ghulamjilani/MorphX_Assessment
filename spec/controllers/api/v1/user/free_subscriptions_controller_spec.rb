# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::FreeSubscriptionsController do
  let(:organization) { create(:organization, enable_free_subscriptions: true) }
  let(:current_user) { organization.user }
  let(:channel) { create(:listed_channel, organization: organization) }
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
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      context 'when given email' do
        before do
          post :create, params: { channel_id: channel.id,
                                  email: Forgery(:internet).email_address,
                                  months: [1, 3, 6, 12].sample }, format: :json
        end

        it { expect(response).to be_successful }
      end

      context 'when given email should enqueue job' do
        it 'creates new job' do
          expect do
            post :create, params: { channel_id: channel.id,
                                    email: Forgery(:internet).email_address,
                                    months: [1, 3, 6, 12].sample }, format: :json
          end.to change(FreeSubscriptions::Create.jobs, :size).by(1)
        end
      end
    end
  end
end
