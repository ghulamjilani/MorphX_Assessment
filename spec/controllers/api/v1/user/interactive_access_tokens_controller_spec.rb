# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::InteractiveAccessTokensController do
  let(:interactive_access_token) { create(:interactive_access_token_active) }
  let(:session) { interactive_access_token.session }
  let(:room) { session.room }
  let(:current_user) { session.presenter.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      let(:params) { { session_id: session.id } }

      before do
        get :index, params: params, format: :json
      end

      context 'when given no session id' do
        let(:params) { {} }

        it { expect(response).not_to be_successful }
      end

      context 'when given no other params' do
        render_views

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given individual param' do
        let(:params) { { session_id: session.id, individual: true } }

        it { expect(response).to be_successful }
      end

      context 'when given shared param' do
        let(:params) { { session_id: session.id, shared: true } }

        it { expect(response).to be_successful }
      end
    end

    describe 'GET show:' do
      let(:params) { { id: interactive_access_token.id } }

      before do
        get :show, params: params, format: :json
      end

      context 'when current user is session presenter' do
        render_views

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when current user is session co-presenter' do
        let(:co_presentership) { create(:session_co_presentership, session: interactive_access_token.session) }
        let(:current_user) { co_presentership.presenter.user }

        it { expect(response).to be_successful }
      end

      context 'when current user is session participant' do
        let(:session_participation) { create(:session_participation, session: interactive_access_token.session) }
        let(:current_user) { session_participation.participant.user }

        it { expect(response).not_to be_successful }
      end
    end

    describe 'POST create:' do
      let(:params) { { session_id: interactive_access_token.session_id, individual: true } }

      before do
        post :create, params: params, format: :json
      end

      context 'when current_user is not session presenter' do
        let(:session_participation) { create(:session_participation, session: interactive_access_token.session) }
        let(:current_user) { session_participation.participant.user }

        it { expect(response).not_to be_successful }
      end

      context 'when creating another individual token' do
        let(:interactive_access_token) { create(:interactive_access_token_individual) }

        it { expect(response).to be_successful }
      end

      # context 'when creating another shared token' do
      #   let(:interactive_access_token) { create(:interactive_access_token_shared) }
      #   let(:params) { { session_id: interactive_access_token.session_id, individual: false } }

      #   it { expect(response).not_to be_successful }
      # end
    end

    describe 'PUT update:' do
      it 'updates access token' do
        interactive_access_token

        expect do
          put :update, params: { id: interactive_access_token.id }, format: :json
          interactive_access_token.reload
        end.to change(interactive_access_token, :token)
      end
    end

    describe 'DELETE destroy:' do
      it 'destroys token' do
        interactive_access_token

        expect do
          delete :destroy, params: { id: interactive_access_token.id }, format: :json
        end.to change(InteractiveAccessToken, :count)
      end
    end
  end
end
