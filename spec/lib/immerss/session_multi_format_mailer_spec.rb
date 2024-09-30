# frozen_string_literal: true

require 'spec_helper'

describe Immerss::SessionMultiFormatMailer do
  let(:user) { create(:user) }
  let(:participant) { create(:participant) }
  let(:session) { create(:session) }

  describe '#wishlist_session' do
    subject(:mail_method) { described_class.new.wishlist_session(user.id, session.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.presenter.user.email, subject: 'Customer added your session to a wish list')])
      )
    end
  end

  describe '#user_accepted_your_session_invitation' do
    subject(:mail_method) { described_class.new.user_accepted_your_session_invitation(session.id, user.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.organizer.email, subject: 'Your invitation was accepted')])
      )
    end
  end

  describe '#user_rejected_your_session_invitation' do
    subject(:mail_method) { described_class.new.user_rejected_your_session_invitation(session.id, user.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.organizer.email, subject: 'Your invitation was declined')])
      )
    end
  end

  describe '#participant_invited_to_abstract_session' do
    subject(:mail_method) { described_class.new.participant_invited_to_abstract_session(session.id, participant.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: participant.user.email, subject: "New #{session.class.name} Invitation from #{session.organizer.public_display_name}")])
      )
    end
  end

  describe '#purchases_summary_for_organizer' do
    subject(:mail_method) { described_class.new.purchases_summary_for_organizer(session.id) }

    let(:session) { create(:session_participation).session }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.organizer.email, subject: 'Purchases Overview')])
      )
    end
  end

  describe '#start_reminder' do
    subject(:mail_method) { described_class.new.start_reminder(session.id, session.presenter.user.id) }

    let(:session) { create(:session_participation).session }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.presenter.user.email, subject: "#{session.always_present_title} be starting soon!")])
      )
    end
  end

  describe '#session_no_stream_stop_scheduled' do
    subject(:mail_method) { described_class.new.session_no_stream_stop_scheduled(session.id) }

    it 'does not fail' do
      expect { mail_method.deliver }.not_to(raise_error)
    end

    it 'enqueues deliver' do
      mail_method.deliver
      expect(ActionMailer::MailDeliveryJob).to(
        have_been_enqueued.with('ActionMailer::Base', 'mail', 'deliver_now',
                                args: [a_hash_including(to: session.presenter.user.email, subject: 'Your session will be stopped in 5 minutes')])
      )
    end
  end
end
