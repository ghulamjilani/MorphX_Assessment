# frozen_string_literal: true

require 'spec_helper'

describe Plutus::Account, '.recreate_plutus_accounts' do
  context 'when given all accounts created' do
    it 'can load all accounts from Accounts:: namespace' do
      present_accounts = described_class.where(name: Accounts::ALL).collect(&:name)

      expect(present_accounts.sort).to eq(Accounts::ALL.sort)
    end
  end
end
