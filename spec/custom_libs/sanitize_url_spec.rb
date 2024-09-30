# frozen_string_literal: true

require 'spec_helper'

describe SanitizeUrl do
  describe '.sanitize_url' do
    context 'when url is valid and includes protocol' do
      let(:url) { "https://#{Forgery(:internet).domain_name}/#{Forgery(:lorem_ipsum).words(3, random: true).split.map(&:parameterize).join('/')}" }

      it { expect { described_class.sanitize_url(url) }.not_to raise_error }

      it { expect(described_class.sanitize_url(url)).to eq(url) }
    end

    context 'when url is valid and has no protocol' do
      let(:url) { "#{Forgery(:internet).domain_name}/#{Forgery(:lorem_ipsum).words(3, random: true).split.map(&:parameterize).join('/')}" }

      it { expect { described_class.sanitize_url(url) }.not_to raise_error }

      it { expect(described_class.sanitize_url(url)).to be_starts_with('https://') }

      it { expect(described_class.sanitize_url(url, default_scheme: 'http')).to be_starts_with('http://') }
    end
  end
end
