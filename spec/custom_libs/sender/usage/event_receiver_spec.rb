# frozen_string_literal: true

require 'spec_helper'

describe Sender::Usage::EventReceiver do
  let(:user) { create(:user) }
  let(:messages) { JSON.parse(File.read(Rails.root.join('spec/fixtures/api_responses/usage/event_receiver/messages.json'))) }
  let(:response_body) { { response: { messages: messages } }.to_json }

  before do
    quoted_base_url = Regexp.quote(::Usage.config.dig(:event_receiver, :base_url))
    stub_request(:post, Regexp.new("^#{quoted_base_url}")).to_return(status: 200, body: response_body, headers: {})
  end

  describe '#user_messages' do
    it { expect { described_class.new(user).user_messages(messages) }.not_to raise_error }

    it { expect(described_class.new(user).user_messages(messages)).to be_present }
  end

  describe '#system_messages' do
    it { expect { described_class.new(user).system_messages(messages) }.not_to raise_error }

    it { expect(described_class.new(user).system_messages(messages)).to be_present }
  end
end
