# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsHelper do
  let(:helper1) do
    helper = Object.new
    helper.extend described_class
    helper
  end

  describe '#select_channel_option_text(channel)' do
    context 'when Listed channel' do
      let(:listed_channel) { create(:listed_channel) }

      it 'return correct message' do
        expect(helper1.select_channel_option_text(listed_channel)).to eq(listed_channel.title)
      end
    end

    context 'when Unlisted channel' do
      let(:approved_channel) { create(:approved_channel) }

      it 'return correct message' do
        expect(helper1.select_channel_option_text(approved_channel)).to eq(
          approved_channel.title += ' - This channel is unlisted, please make it listed first.'
        )
      end
    end

    context 'when Channel with subscription' do
      let(:channel_with_subscription) { create(:listed_channel) }

      before do
        create(:subscription, channel: channel_with_subscription)
      end

      it 'return correct message' do
        expect(helper1.select_channel_option_text(channel_with_subscription)).to eq(
          channel_with_subscription.title += ' - This channel already has a subscription.'
        )
      end
    end
  end

  describe '#select_channel_option_attributes(channel)' do
    context 'when Listed channel' do
      let(:listed_channel) { create(:listed_channel) }

      it 'return correct message' do
        expect(helper1.select_channel_option_attributes(listed_channel)).to include(
          'data-is-listed': true,
          'data-is-subscription-present': false,
          disabled: false
        )
      end
    end

    context 'when Unlisted channel' do
      let(:approved_channel) { create(:approved_channel) }

      it 'return correct message' do
        expect(helper1.select_channel_option_attributes(approved_channel)).to include(
          'data-is-listed': false,
          'data-is-subscription-present': false,
          disabled: true
        )
      end
    end

    context 'when Channel with subscription' do
      let(:channel_with_subscription) { create(:listed_channel) }

      before do
        create(:subscription, channel: channel_with_subscription)
      end

      it 'return correct message' do
        expect(helper1.select_channel_option_attributes(channel_with_subscription)).to include(
          'data-is-listed': true,
          'data-is-subscription-present': true,
          disabled: true
        )
      end
    end
  end
end
