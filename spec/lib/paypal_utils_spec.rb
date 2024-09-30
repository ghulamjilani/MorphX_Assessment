# frozen_string_literal: true

require 'spec_helper'

describe PaypalUtils do
  context 'when encrypted data marshaling' do
    let(:encrypted_data) { described_class.paypal_number(abstract_session: Session.new(id: 123), user_id: 111) }

    it { expect(encrypted_data).to be_present }

    it {
      expect(described_class.decrypt_paypal_number(encrypted_data)).to eq({ model_class: 'Session', user_id: 111,
                                                                            model_id: 123 })
    }

    it { expect(described_class.decrypt_paypal_number('fake')).to be_blank }
  end
end
