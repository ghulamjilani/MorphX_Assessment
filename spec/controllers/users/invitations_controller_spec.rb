# frozen_string_literal: true

require 'spec_helper'

describe Users::InvitationsController do
  describe 'GET :edit' do
    let(:raw_invitation_token) { invited_user.raw_invitation_token }
    let(:current_user) { create(:user) }
    let(:invited_user) do
      User.invite!({
                     email: Forgery(:internet).email_address,
                     first_name: Forgery(:name).first_name,
                     last_name: Forgery(:name).last_name
                   }, current_user) do |u|
        u.before_create_generic_callbacks_and_skip_validation
        u.skip_invitation = true
      end
    end

    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]

      get :edit, params: { invitation_token: raw_invitation_token }, format: request_format
    end

    context 'when .json request format' do
      let(:request_format) { :json }

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end

    context 'when .html request format' do
      let(:request_format) { :html }

      it { expect(response).to be_successful }
    end
  end

  describe 'POST :create' do
    let(:current_user) { create(:user) }

    before { sign_in(current_user, scope: :user) }

    it 'invites user by email' do
      @request.env['devise.mapping'] = Devise.mappings[:user]

      initial_user_count = User.count

      post :create, params: { user: { email: 'hey@gmail.com' } }

      expect(User.count).to eq(initial_user_count + 1)

      expect(response).to be_redirect
    end
  end
end
