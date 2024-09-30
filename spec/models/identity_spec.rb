# frozen_string_literal: true
require 'spec_helper'

describe Identity do
  describe 'validations' do
    it 'expects unique uid' do
      create(:facebook_identity, uid: 'uid111')
      expect do
        create(:facebook_identity, uid: 'uid111')
      end.to raise_error ActiveRecord::RecordInvalid
    end

    context 'when given twitter provider' do
      it 'expects secret and token parameters to be present' do
        identity = described_class.new(provider: :twitter)
        expect(identity).to be_invalid

        expect(identity.errors.full_messages).to include "Token can't be blank"
        expect(identity.errors.full_messages).to include "Secret can't be blank"
      end
    end

    context 'when given facebook provider' do
      it 'expects token, expires, expires_at parameters to be present' do
        identity = described_class.new(provider: :facebook)
        expect(identity).to be_invalid

        expect(identity.errors.full_messages).to include "Token can't be blank"
        expect(identity.errors.full_messages).to include "Expires can't be blank"
        expect(identity.errors.full_messages).to include "Expires at can't be blank"
      end
    end
  end
end
