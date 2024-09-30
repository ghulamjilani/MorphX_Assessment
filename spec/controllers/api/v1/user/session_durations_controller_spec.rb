# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::SessionDurationsController do
  let(:session) { create(:immersive_session, duration: 30) }
  let(:user) { session.organizer }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }
  let(:changes_left) { 3 }

  let(:response_body) { JSON.parse(response.body) }

  describe '.json request format' do
    render_views

    before do
      request.headers['Authorization'] = auth_header_value
      session.duration_change_times_left = changes_left
      session.update_column(:start_at, 1.minute.ago)
    end

    describe 'GET show:' do
      before do
        get :show, params: { session_id: session.id }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(response_body['response']['session']['session_duration']['duration_change_times_left']).to eq(changes_left) }
    end

    describe 'POST create:' do
      it 'increases duration' do
        expect do
          post :create, params: { session_id: session.id }, format: :json
          session.reload
        end.to change(session, :duration).and change(session, :duration_change_times_left)
      end

      describe 'request results' do
        before do
          post :create, params: { session_id: session.id }, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response_body['response']['session']['session_duration']['duration_change_times_left']).to eq(changes_left - 1) }
      end
    end

    describe 'DELETE destroy:' do
      it 'decreases duration' do
        expect do
          delete :destroy, params: { session_id: session.id }, format: :json
          session.reload
        end.to change(session, :duration).and change(session, :duration_change_times_left)
      end

      describe 'request results' do
        before do
          delete :destroy, params: { session_id: session.id }, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response_body['response']['session']['session_duration']['duration_change_times_left']).to eq(changes_left - 1) }
      end
    end
  end
end
