# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::SessionsController do
  let(:session) { create(:immersive_session) }
  let(:reason_id) { create(:abstract_session_cancel_reason).id }
  let(:user) { session.organizer }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  let(:response_body) { JSON.parse(response.body) }

  describe '.json request format' do
    describe 'GET nearest_session:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :nearest_session, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          render_views

          before do
            get :nearest_session, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'GET index:' do
      before do
        request.headers['Authorization'] = auth_header_value
        get :index, params: params, format: :json
      end

      context 'when given no params' do
        let(:params) { {} }

        it { expect(response).to be_successful }
      end

      context 'when given channel_id param' do
        let(:params) { { channel_id: session.channel_id } }

        it { expect(response).to be_successful }
      end

      context 'when given presenter_id param' do
        let(:params) { { presenter_id: session.presenter_id } }

        it { expect(response).to be_successful }
      end

      context 'when given organization_id param' do
        let(:params) { { organization_id: session.channel.organization_id } }

        it { expect(response).to be_successful }
      end

      context 'when given start_at_from param' do
        let(:params) { { start_at_from: (session.start_at - 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given start_at_to param' do
        let(:params) { { start_at_to: (session.start_at + 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given start_at_from and start_at_to param' do
        let(:params) { { start_at_from: (session.start_at - 1.hour), start_at_to: (session.start_at + 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given end_at_from param' do
        let(:params) { { end_at_from: (session.end_at - 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given end_at_to param' do
        let(:params) { { end_at_to: (session.end_at + 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given end_at_from and end_at_to param' do
        let(:params) { { end_at_from: (session.end_at - 1.hour), end_at_to: (session.end_at + 1.hour) } }

        it { expect(response).to be_successful }
      end

      context 'when given duration_from and duration_to param' do
        let(:params) { { duration_from: (session.duration - 5), duration_to: (session.duration + 5) } }

        it { expect(response).to be_successful }
      end

      context 'when given order_by and order params' do
        let(:params) { { order_by: 'end_at', order: 'desc', limit: 1, offset: 1 } }

        it { expect(response).to be_successful }
      end
    end

    describe 'GET new:' do
      render_views

      before do
        request.headers['Authorization'] = auth_header_value
      end

      context 'given no params' do
        before do
          get :new, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'given valid channel_id param' do
        before do
          get :new, params: { channel_id: session.channel_id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      render_views

      before do
        request.headers['Authorization'] = auth_header_value
      end

      context 'given no params' do
        before do
          post :create, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'given valid channel_id param' do
        let(:recorded_free) { record ? [true, false].sample : nil }
        let(:recorded_access_cost) do
          if !record
            nil
          elsif recorded_free
            0
          else
            (1.0..15.0).step(0.2).to_a.sample.round(2)
          end
        end
        let(:params) do
          {
            channel_id: session.channel_id,
            private: [true, false].sample,
            record: record,
            recorded_free: recorded_free,
            recorded_access_cost: recorded_access_cost,
            allow_chat: [true, false].sample,
            title: Forgery(:lorem_ipsum).words(4, random: true),
            duration: (15..180).step(5).to_a.sample,
            max_number_of_immersive_participants: (2..49).to_a.sample
          }
        end

        before do
          post :create, params: params, format: :json
        end

        context 'given record set to true' do
          let(:record) { 1 }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
          it { expect(assigns(:session).channel_id).to eq(session.channel_id) }
          it { expect(assigns(:session).recorded_purchase_price).not_to be_nil }
        end

        context 'given record set to null' do
          let(:record) { nil }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
          it { expect(assigns(:session).channel_id).to eq(session.channel_id) }
          it { expect(assigns(:session).recorded_purchase_price).to be_nil }
        end
      end
    end

    describe 'POST :confirm_purchase' do
      render_views

      before do
        request.headers['Authorization'] = auth_header_value
      end

      context 'when immersive participant' do
        context 'when given new free trial session' do
          let(:session) { create(:free_trial_immersive_session) }
          let(:user) { create(:participant).user }

          it 'works for first time participants' do
            post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_IMMERSIVE }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when given completely free session' do
          let(:session) do
            create(:completely_free_session).tap do |s|
              s.status = ::Session::Statuses::PUBLISHED; s.save!
            end
          end
          let(:user) { create(:participant).user }

          it 'works for first time participants' do
            post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_IMMERSIVE }, format: :json
            expect(response).to be_successful
          end
        end
      end

      context 'when livestream participant' do
        context 'when given new free trial session' do
          let!(:session) { create(:free_trial_livestream_session) }
          let(:user) { create(:participant).user }

          it 'works for first time participants' do
            post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_LIVESTREAM }, format: :json
            expect(response).to be_successful
          end
        end
      end

      context 'when PAID and system_credit_balance methods' do
        before do
          allow_any_instance_of(User).to receive(:system_credit_balance).and_return(999)
        end

        context 'when given new session' do
          let!(:session) { create(:session_with_livestream_only_delivery) }
          let(:user) { create(:participant).user }

          it 'works for paid livestream participants' do
            post :confirm_purchase, params: { id: session.id, type: ObtainTypes::PAID_LIVESTREAM }, format: :json
            expect(response).to be_successful
          end
        end

        context 'works for paid vods participants' do
          let!(:session) { create(:recorded_session) }
          let(:user) { create(:participant).user }

          it 'works for participants' do
            post :confirm_purchase, params: { id: session.id, type: ObtainTypes::PAID_VOD }, format: :json
            expect(response).to be_successful
          end
        end

        context 'works for paid immersive participants' do
          let!(:session) { create(:published_session) }
          let(:user) { create(:participant).user }

          it 'works for participants' do
            post :confirm_purchase,
                 params: { id: session.id, type: ObtainTypes::PAID_IMMERSIVE, stripe_token: @stripe_test_helper.generate_card_token }, format: :json
            expect(response).to be_successful
          end
        end
      end
    end

    describe 'DELETE destroy:' do
      render_views

      before do
        request.headers['Authorization'] = auth_header_value
        delete :destroy, params: { id: session.id, cancel_reason_id: reason_id }, format: :json
        session.reload
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(session).to be_cancelled }
    end
  end
end
