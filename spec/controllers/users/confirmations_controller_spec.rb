# frozen_string_literal: true

require 'spec_helper'

describe Users::ConfirmationsController do
  describe 'GET :show' do
    let!(:user_without_confirmed_email) do
      create(:user, confirmed_at: false).tap do |user|
        # extracted/copied from Devise's source
        raw, enc = Devise.token_generator.generate(User, :confirmation_token)
        @raw_confirmation_token = raw
        user.update_attribute(:confirmation_token, enc)
        user.update_attribute(:confirmation_sent_at, Time.now.utc)
      end
    end

    before do
      expect(user_without_confirmed_email.reload).not_to be_confirmed
    end

    context 'when confirmation_token param is present and valid' do
      before do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        get :show, params: { confirmation_token: @raw_confirmation_token }
      end

      it { expect(user_without_confirmed_email.reload).to be_confirmed }

      it { expect(response).to redirect_to(root_path) }

      it { expect(assigns(:current_user)).not_to be_blank }
    end

    context 'when confirmation_token param missing' do
      before do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        get :show, params: {}
      end

      it { expect(response).to redirect_to(root_path) }

      it { expect(flash[:error]).to be_present }

      it { expect(user_without_confirmed_email.reload).not_to be_confirmed }

      it { expect(assigns(:current_user)).to be_blank }
    end

    context 'when confirmation_token param is wrong' do
      before do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        get :show, params: { confirmation_token: SecureRandom.alphanumeric(8) }
      end

      it { expect(response).to redirect_to(root_path) }

      it { expect(flash[:error]).to be_present }

      it { expect(user_without_confirmed_email.reload).not_to be_confirmed }

      it { expect(assigns(:current_user)).to be_blank }
    end
  end
end
