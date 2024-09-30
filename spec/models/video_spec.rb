# frozen_string_literal: true
require 'spec_helper'

describe Video do
  let(:video) { create(:video) }

  describe 'scopes' do
    describe '.processing' do
      it { expect { described_class.processing }.not_to raise_error }
    end
  end

  describe 'callbacks' do
    let(:video) { create(:video, status: ::Video::Statuses::FOUND) }

    before do
      video
    end

    it 'schedules perform calculate usage task' do
      expect { video.update(status: ::Video::Statuses::DONE) }.to change(VideoJobs::VodStorage::CheckStorageRecordsJob.jobs, :size)
    end

    it 'notifies session channel about video publishing' do
      allow(video).to receive(:notify_session_video_published)
      video.update(status: ::Video::Statuses::DONE)
      expect(video).to have_received(:notify_session_video_published)
    end

    describe '#notify_video_ready_to_transcode' do
      context 'when recording was enabled for session' do
        let(:video) { create(:video_downloaded) }

        it 'notifies presenter that video is ready' do
          video.update(status: ::Video::Statuses::ORIGINAL_VERIFIED)

          expect(ApplicationMailDeliveryJob).to(
            have_been_enqueued.with('VideoMailer', 'uploaded', 'deliver_now', args: [video.id])
          )
        end
      end

      context 'when recording was disabled for session' do
        let(:video) { create(:video_downloaded, room: create(:session).room) }

        it 'does not notify presenter that video is ready' do
          video.update(status: ::Video::Statuses::ORIGINAL_VERIFIED)

          expect(ApplicationMailDeliveryJob).not_to(
            have_been_enqueued.with('VideoMailer', 'uploaded', 'deliver_now', args: [video.id])
          )
        end
      end

      context 'when no room was found for video' do
        let(:video) { create(:video_downloaded, room: nil, user: nil) }

        it { expect { video.update(status: ::Video::Statuses::ORIGINAL_VERIFIED) }.not_to raise_error }

        it 'does not notify presenter that video is ready' do
          video.update(status: ::Video::Statuses::ORIGINAL_VERIFIED)
          expect(ApplicationMailDeliveryJob).not_to(
            have_been_enqueued.with('VideoMailer', 'uploaded', 'deliver_now', args: [video.id])
          )
        end
      end
    end
  end

  describe '#s3_domain' do
    it 'returns correct domain' do
      expect(video.s3_domain).to eq(ENV['HWCDN'])
    end

    it 'with old_id returns correct domain ' do
      video.old_id = 123
      expect(video.s3_domain).to eq(ENV['S3_IMMERSS_DOMAIN'])
    end
  end

  describe '#s3_path' do
    context 'when video.old_id.present?' do
      before { video.old_id = 123 }

      context 'and room.old_id.present?' do
        before { video.room.old_id = 456 }

        it { expect(video.s3_path).to eq("/#{video.user_id}/#{video.room.old_id}") }
      end

      it('when room.old_id.present?') do
        video.room.old_id = 456
        expect(video.s3_path).to eq("/#{video.user_id}/#{video.room.old_id}")
      end

      it('when room.old_id.nil?') { expect(video.s3_path).to eq("/#{video.user_id}/#{video.room_id}") }
    end

    context 'when video.old_id.nil?' do
      it { expect(video.s3_path).to eq("/#{video.user_id}/#{video.room_id}") }
    end
  end

  describe '#original_url' do
    context 'when original_name.present?' do
      before { video.original_name = 'OriginalName' }

      it { expect(video.original_url).to eq("https://#{video.s3_domain}#{video.s3_path}/#{video.original_name}") }
    end

    context 'when original_name.absent? and filename.present?' do
      it { expect(video.original_url).to eq("https://#{video.s3_domain}#{video.s3_path}/#{video.filename}") }
    end
  end

  describe '#share_title' do
    subject(:title) { video.share_title }

    it { expect { title }.not_to raise_error }

    context 'when title is present' do
      let(:video) { create(:video, title: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(title).to be_truthy }
    end

    context 'when title is null' do
      let(:video) { create(:video, title: nil) }

      it { expect(title).to be_truthy }
    end
  end

  describe '#share_description' do
    subject(:description) { video.share_description }

    it { expect { description }.not_to raise_error }

    context 'when description is present' do
      let(:video) { create(:video, description: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(description).to be_truthy }
    end

    context 'when description is null' do
      let(:video) { create(:video, description: nil) }

      it { expect(description).to be_truthy }
    end
  end

  describe '#processing?' do
    let(:video) { build(:video, status: described_class::Statuses::ALL.sample) }

    it { expect { video.processing? }.not_to raise_error }

    context 'when status is processing' do
      let(:video) { build(:video, status: described_class::Statuses::PROCESSING.sample) }

      it { expect(video).to be_processing }
    end

    context 'when status is not processing' do
      let(:video) { build(:video, status: (described_class::Statuses::ALL - described_class::Statuses::PROCESSING).sample) }

      it { expect(video).not_to be_processing }
    end
  end

  describe '#unique_view_group_start_at' do
    let(:video) { build(:video) }

    it { expect { video.unique_view_group_start_at }.not_to raise_error }
  end

  describe 'private methods' do
    describe '#status_changed_callbacks' do
      it { expect { video.send :status_changed_callbacks }.not_to raise_error }
    end

    describe '#notify_session_video_published' do
      let(:video) { create(:video_published) }

      it { expect { video.send :notify_session_video_published }.not_to raise_error }

      it 'notifies session' do
        allow(SessionsChannel).to receive(:broadcast_to)
        video.send :notify_session_video_published
        expect(SessionsChannel).to have_received(:broadcast_to)
      end
    end
  end
end
