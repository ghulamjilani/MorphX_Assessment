# frozen_string_literal: true

require 'spec_helper'

describe Immerss::ChannelMultiFormatMailer do
  let(:user) { create(:user) }
  let(:channel) { create(:channel) }

  describe '#user_accepted_your_channel_invitation' do
    subject(:mail_method) { described_class.new.user_accepted_your_channel_invitation(channel.id, user.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args:[a_hash_including(to: channel.organizer.email, subject: 'Your invitation was accepted')])
      )
    end
  end

  describe '#user_rejected_your_channel_invitation' do
    subject(:mail_method) { described_class.new.user_rejected_your_channel_invitation(channel.id, user.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: channel.organizer.email, subject: 'Your invitation was declined')])
      )
    end
  end
end
