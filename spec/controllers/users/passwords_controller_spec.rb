# frozen_string_literal: true

require 'spec_helper'

describe Users::PasswordsController do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST :create' do
    let(:user) { create(:user) }

    context 'when requesting password reset' do
      it 'resets password' do
        post :create, params: { user: { email: user.email } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PUT :update' do
    context 'when user has not accepted previous invitation request' do
      let(:inviter) { create(:user) }
      let(:invitee) do
        User.invite!({ email: 'invited.private.event.participant@example.com' }, inviter,
                     &:before_create_generic_callbacks_and_skip_validation)
      end

      it 'can reset password even if not accepted previous invitation request' do
        invitee
        User.send_reset_password_instructions(email: invitee.email) # it assigns reset_password_token
        invitee.reload

        put :update,
            params: { user: { password: 'Abcdef123!', password_confirmation: 'Abcdef123!',
                              reset_password_token: invitee.send_reset_password_instructions } }

        expect(response).to be_redirect
      end
    end
  end
end
