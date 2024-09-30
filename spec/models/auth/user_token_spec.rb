# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Auth::UserToken, type: :model do
  describe '#jwt_secret' do
    context 'with raise_exception' do
      let(:auth_user_token) { build(:auth_user_token) }

      it { expect { auth_user_token.jwt_secret }.to raise_error 'Save before call' }
    end

    context 'without raise_exception' do
      let(:auth_user_token) { create(:auth_user_token) }

      it { expect(auth_user_token.jwt_secret).not_to be_empty }
    end
  end
end
