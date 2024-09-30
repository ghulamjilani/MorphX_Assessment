# frozen_string_literal: true

require 'spec_helper'

describe Spa::RoomsController do
  let(:room) { create(:room) }

  render_views

  describe 'GET rooms/:id' do
    context 'when current_user not set' do
      it 'redirects users without permissions to root' do
        get :show, params: { id: room.id }
        expect(response).to be_redirect
      end
    end

    context 'when current_user is presenter' do
      let(:current_user) { room.presenter_user }

      before do
        sign_in(current_user)
      end

      it 'works' do
        get :show, params: { id: room.id }
        expect(response).to be_successful
      end
    end

    context 'when current_user is participant' do
      let(:session_participation) { create(:session_participation) }
      let(:room) { session_participation.session.room }
      let(:current_user) { session_participation.participant.user }

      before do
        sign_in(current_user)
      end

      it 'works' do
        get :show, params: { id: room.id }
        expect(response).to be_successful
      end
    end

    context 'when current_user has no access' do
      let(:current_user) { create(:user) }

      before do
        sign_in(current_user)
      end

      it 'redirects to root' do
        get :show, params: { id: room.id }
        expect(response).to be_redirect
      end
    end
  end
end
