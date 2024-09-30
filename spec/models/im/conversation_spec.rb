# frozen_string_literal: true
require 'spec_helper'

describe Im::Conversation do
  let(:im_conversation) { create(:approved_channel).im_conversation }

  describe 'Instance methods' do
    describe '#conversationable' do
      it { expect { im_conversation.conversationable }.not_to raise_error }

      it { expect(im_conversation.conversationable).to be_present }
    end

    describe '#last_message' do
      let(:im_conversation) { create(:im_message).conversation }

      it { expect { im_conversation.last_message }.not_to raise_error }

      it { expect(im_conversation.last_message).to be_present }
    end
  end
end
