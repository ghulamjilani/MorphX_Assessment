# frozen_string_literal: true

require 'spec_helper'

describe UtmContentToken do
  context 'when given valid token' do
    let(:url) { described_class.for_user_id_and_email(1, 'david@heinemeierhansson.com') }
    let(:utm) { described_class.new(url) }

    it { expect(url).not_to be_blank }
    it { expect(url).not_to eq('') }

    it { expect(utm).to be_valid }
    it { expect(utm.user_id).to eq(1) }
    it { expect(utm.email).to eq('david@heinemeierhansson.com') }
  end

  context 'when given invalid token' do
    it 'works' do
      expect(described_class.new('fuu')).not_to be_valid
    end
  end
end
