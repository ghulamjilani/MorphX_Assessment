# frozen_string_literal: true

require 'spec_helper'

describe UnsubscribesController do
  let(:user) { create(:user) }

  render_views

  describe 'GET :preview' do
    context 'when given valid token' do
      it 'does not fail' do
        get :preview, params: { token: Tldr::TokenGenerator.new(user.id, :follow_me).token }

        expect(response).to be_successful
      end

      context 'when user signed in' do
        before { sign_in(user, scope: :user) }

        it 'does not fail' do
          get :preview, params: { token: Tldr::TokenGenerator.new(user.id, :follow_me).token }

          expect(response).to be_successful
        end
      end
    end

    context 'when given invalid token' do
      it 'redirects to home page' do
        get :preview, params: { token: 'foo' }

        expect(response).to be_redirect
      end
    end
  end

  describe 'POST :confirm' do
    let(:token) { Tldr::TokenGenerator.new(user.id, :follow_me).token }

    before do
      post :confirm, params: { token: token }
    end

    it { expect(response).to be_successful }

    it { expect(user).not_to be_receives_notification(:follow_me_via_email) }
  end
end
