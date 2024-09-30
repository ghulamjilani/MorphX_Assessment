# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionPublishReminder do
  # before { Timecop.freeze(Time.now) } # to avoid 1sec difference test fails

  describe 'scheduling' do
    it 'is scheduled for new unpublished sessions' do
      # Sidekiq::Testing.inline! do
      #   session = create(:immersive_session, start_at: 6.hours.from_now.beginning_of_hour)
      #
      #   expect(described_class).to have_scheduled(session.id)
      # end
    end
  end

  describe '.perform(session_id)' do
    let!(:session) { create(:immersive_session) }
    let(:notified_user) { session.organizer }

    xit { expect(session.published?).to eq(false) }

    xit "creates mailboxer's notification" do
      Sidekiq::Testing.inline! { described_class.perform_async(session.id) }
      expect(ApplicationMailDeliveryJob).to(
        have_been_enqueued.with('SessionMailer', 'publish_reminder', 'deliver_now', args:[session.id])
      )
    end
  end
end
