# frozen_string_literal: true

require 'spec_helper'

describe VideoJobs::CleanupNotificationsJob do
  let(:video) { create(:video_original_verified) }
  let(:created_days_ago) { 1 }

  before do
    video
    Video.update_all(created_at: created_days_ago.days.ago)
  end

  it { expect { described_class.new.perform }.not_to raise_error }

  context 'when record was enabled for session' do
    it 'notifies owner about cleanup' do
      described_class.new.perform
      expect(ApplicationMailDeliveryJob).to(have_been_enqueued.with('VideoMailer',
                                                                    'cleanup_notification',
                                                                    'deliver_now',
                                                                    args: [{ user_id: video.user_id, video_ids: [video.id], time_interval: created_days_ago }]))
    end
  end

  context 'when record was disabled for session' do
    let(:video) { create(:video_original_verified, room: create(:session).room) }

    it 'does not notify owner about cleanup' do
      described_class.new.perform
      expect(ApplicationMailDeliveryJob).not_to(have_been_enqueued.with('VideoMailer',
                                                                        'cleanup_notification',
                                                                        'deliver_now',
                                                                        args: [{ user_id: video.user_id, video_ids: [video.id], time_interval: created_days_ago }]))
    end
  end
end
