# frozen_string_literal: true

require 'spec_helper'

describe ProfilesController do
  describe 'GET :stream_options' do
    render_views
    let(:current_user) { create(:organization).user }

    before do
      sign_in current_user, scope: :user
    end

    let(:current_user) { create(:organization).user }

    it 'does not fail' do
      get :stream_options
      expect(response).to be_successful
    end
  end

  describe 'GET :edit_public' do
    render_views
    let(:current_user) { create(:user) }

    before do
      sign_in current_user, scope: :user
    end

    let(:current_user) { create(:user) }

    it 'does not fail' do
      get :edit_public
      expect(response).to be_successful
    end
  end

  describe 'GET :edit_application' do
    render_views
    let(:current_user) { create(:user) }

    before do
      sign_in current_user, scope: :user
    end

    it 'does not fail' do
      get :edit_application
      expect(response).to be_successful
    end
  end

  describe 'POST :update_application' do
    # render_views
    let(:current_user) { create(:user, password: 'Abcdef123!', password_confirmation: 'Abcdef123!') }

    before do
      sign_in current_user, scope: :user
    end

    it 'does not fail when changing email' do
      post :update_application, params: { profile: { email: Forgery('internet').email_address } }
      expect(response).to be_redirect
    end

    it 'does not fail when changing password' do
      post :update_application,
           params: { profile: { current_password: 'Abcdef123!', password: 'New_password1!',
                                password_confirmation: 'New_password1!' } }
      expect(response).to be_redirect
    end

    it 'fail when changing password' do
      post :update_application,
           params: { profile: { password: 'New_password1!', password_confirmation: 'New_password1!' } }
      expect(response).not_to be_successful
    end
  end

  describe 'DELETE :destroy' do
    before do
      sign_in current_user, scope: :user
    end

    context 'when user does not have active subscriptions' do
      let(:current_user) { create(:user) }

      it 'marks user as destroyed' do
        expect_any_instance_of(User).to receive(:mark_as_destroyed)
        delete :destroy
      end

      it 'signs out' do
        delete :destroy
        expect(response).to be_redirect
      end
    end

    context 'when user has active subscriptions' do
      let(:current_user) { create(:stripe_db_subscription, status: :active).user }

      render_views

      it 'redirects to subscription page' do
        delete :destroy
        expect(response).to redirect_to(my_subscriptions_dashboard_money_index_path)
      end

      it 'displays error notice' do
        delete :destroy
        expect(flash[:error]).to include('Sorry, we cannot delete your account before all your subscriptions are canceled.')
      end
    end
  end

  describe 'POST :disconnect_social_account' do
    before do
      sign_in current_user, scope: :user
    end

    let(:current_user) { create(:user) }

    before do
      sign_in current_user, scope: :user
      @request.env['HTTP_REFERER'] = 'http://localhost:3000/whatever'
      create(:facebook_identity, user: current_user)
    end

    it 'works' do
      post :disconnect_social_account, params: { provider: 'facebook' }
      expect(response).to be_redirect
    end
  end

  describe 'GET :edit_notifications' do
    render_views

    let(:current_user) { create(:user) }

    before do
      sign_in current_user, scope: :user
    end

    it 'does not fail' do
      get :edit_notifications
      expect(response).to be_successful
    end
  end
end
