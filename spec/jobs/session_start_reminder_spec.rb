# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionStartReminder do
  # before { Timecop.freeze(Time.now) } # to avoid 1sec difference test fails

  describe 'scheduling' do
    context 'when co-presenters' do
      it 'is scheduled for new co-presenters and cancelled if co-presentership is destroyed' do
        # Sidekiq::Testing.inline! do
        # presenter1 = create(:presenter)
        # session = create(:immersive_session)
        # session.co_presenters << presenter1
        #
        # expect(described_class).to have_scheduled(session.id, presenter1.user.id, EmailOnlyFormatPolicy.to_s)
        #
        # session.session_co_presenterships.first!.destroy
        # expect(described_class).not_to have_scheduled(session.id, presenter1.user.id, EmailOnlyFormatPolicy.to_s)
        # end
      end
    end

    context 'when participants' do
      let(:participant) { create(:participant) }

      let(:session_with_participants) do
        create(:immersive_session).tap { |session| session.immersive_participants << participant }
      end

      it 'is scheduled for newly paid participant and cancelled if participantship is destroyed' do
        # Sidekiq::Testing.inline! do
        #
        # session_with_participants
        # expect(described_class).to have_scheduled(session_with_participants.id, participant.user.id, EmailOnlyFormatPolicy.to_s)
        #
        # session_with_participants.session_participations.first!.destroy
        # expect(described_class).not_to have_scheduled(session_with_participants.id, participant.user.id, EmailOnlyFormatPolicy.to_s)
        # end
      end
    end
  end

  describe '.perform(session_id, user_id, policy_method)' do
    let!(:session) { create(:immersive_session, custom_description_field_value: 'not blank') }
    let(:notified_user) { create(:participant).user }

    before { session.immersive_participants << notified_user.participant }

    it "count mailboxer's notification" do
      count = Mailboxer::Notification.count
      Sidekiq::Testing.inline! do
        described_class.perform_async(session.id, notified_user.id, WebOnlyFormatPolicy.to_s)
      end
      expect(Mailboxer::Notification.count).to eq(count + 1)
    end

    it "creates mailboxer's notification" do
      Sidekiq::Testing.inline! do
        described_class.perform_async(session.id, notified_user.id, WebOnlyFormatPolicy.to_s)
      end
      expect(Mailboxer::Notification.last.notified_object).to eq(notified_user)
    end
  end
end
