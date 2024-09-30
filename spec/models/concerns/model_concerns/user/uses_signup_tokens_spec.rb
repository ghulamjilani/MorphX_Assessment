# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::UsesSignupTokens do
  describe '#can_use_wizard?' do
    context 'when signup enabled' do
      context 'when user has already completed wizard' do
        let(:user) { create(:listed_channel).user }

        it { expect(user).not_to be_can_use_wizard }
      end

      context 'when user has not started wizard' do
        let(:user) { create(:user, can_use_wizard: false) }

        it { expect(user).to be_can_use_wizard }
      end
    end

    context 'when signup and wizard disabled' do
      let(:global_credentials) do
        global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
        global_credentials[:sign_up][:enabled] = false
        global_credentials[:wizard][:enabled] = false
        global_credentials
      end

      before do
        allow(Rails.application.credentials).to receive(:global).and_return(global_credentials)
      end

      context 'when user has already completed wizard' do
        let(:user) { create(:listed_channel).user }

        it { expect(user).not_to be_can_use_wizard }
      end

      context 'when user has not started wizard' do
        let(:user) { create(:user) }

        it { expect(user).not_to be_can_use_wizard }
      end

      context 'when user used signup token' do
        let(:user) { create(:user) }
        let(:signup_token) { create(:signup_token) }

        before do
          signup_token.used_by!(user)
        end

        it { expect(user).to be_can_use_wizard }
      end
    end
  end

  describe '#can_use_wizard!' do
    let(:user) { create(:user) }

    it { expect { user.can_use_wizard! }.not_to raise_error }
  end

  describe '#cannot_buy_subscription!' do
    let(:user) { create(:user) }

    it { expect { user.cannot_buy_subscription! }.not_to raise_error }
  end
end
