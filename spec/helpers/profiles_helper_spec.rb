# frozen_string_literal: true

require 'spec_helper'

describe ProfilesHelper do
  describe '#confirmed_phone_numbers(user)' do
    let(:helper1) do
      helper = Object.new
      helper.extend described_class
      helper
    end

    it { expect(helper1.confirmed_phone_numbers(nil)).to eq([]) }

    it 'works' do
      create(:user)
      expect(helper1.confirmed_phone_numbers(nil)).to eq([])
    end

    it 'more works' do
      user = create(:user)
      create(:authy_record, user: user, status: AuthyRecord::Statuses::APPROVED, cellphone: '971126326',
                            country_code: '380')
      expect(helper1.confirmed_phone_numbers(user)).to eq(['+380971126326'])
    end
  end
end
