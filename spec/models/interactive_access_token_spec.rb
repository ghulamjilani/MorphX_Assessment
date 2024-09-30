# frozen_string_literal: true
require 'spec_helper'

describe InteractiveAccessToken do
  let(:access_token) { create(:interactive_access_token_active) }

  describe 'scopes' do
    describe '.individual' do
      subject(:tested_scope) { described_class.individual }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.shared' do
      subject(:tested_scope) { described_class.shared }

      it { expect { tested_scope }.not_to raise_error }
    end
  end

  describe '#refresh_token' do
    subject(:tested_method) { access_token.refresh_token }

    it { expect { tested_method }.not_to raise_error }
    it { expect { tested_method }.to change(access_token, :token) }
  end

  describe '#refresh_token!' do
    subject(:tested_method) { access_token.refresh_token! }

    it { expect { tested_method }.not_to raise_error }
    it { expect { tested_method }.to change(access_token, :token) }
  end

  describe '#absolute_url' do
    subject(:tested_method) { access_token.absolute_url }

    it { expect { tested_method }.not_to raise_error }
  end
end
