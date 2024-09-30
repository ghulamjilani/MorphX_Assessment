# frozen_string_literal: true

require 'spec_helper'

describe AbstractSessionVodIsFullyReadyStatusCheck do
  let(:session) { build(:immersive_session, duration: 30) }

  it 'is queued' do
    expect do
      session.save!
    end.to change(described_class.jobs, :size).by(1)
    # expect(job).to be_present
    # expect(job[:time]).to eq(30.minutes.since(session.start_at))

    session.duration = 60
    session.save!
  end

  context 'when given abstract session that just became fully vod-ready' do
    let(:session1) { create(:immersive_session_with_recorded_delivery) }
    let(:user1) { create(:user) }

    before do
      mailer = double
      allow(mailer).to receive(:deliver_later)
      allow(Mailer).to receive(:vod_just_became_available_for_purchase).once.with(user1.id, session1).and_return(mailer)
    end

    it { expect(session1.vod_waiting_list_is_notified).not_to eq(true) }

    it 'notifies pending members and marks job as done' do
      PendingVodAvailabilityMembership.create!(abstract_session: session1, user: user1)
      session1.room.update!({ vod_is_fully_ready: true })
      Sidekiq::Testing.inline! { described_class.perform_async(session1.class.to_s, session1.id) }
      expect(session1.reload.vod_waiting_list_is_notified).to eq(true)
    end
  end
end
