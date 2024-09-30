# frozen_string_literal: true
require 'spec_helper'

describe Recording do
  let(:recording) { create(:recording) }

  describe 'scopes' do
    describe '.processing' do
      it { expect { described_class.processing }.not_to raise_error }
    end
  end

  describe 'callbacks' do
    let(:recording) { create(:recording, status: :ready_to_tr) }

    before do
      recording
    end

    it 'schedules perform calculate usage task' do
      expect { recording.update(status: :done) }.to not_raise_error.and change(RecordingJobs::VodStorage::CheckStorageRecordsJob.jobs, :size)
    end
  end

  describe '#always_present_description' do
    subject(:description) { recording.always_present_description }

    it { expect { description }.not_to raise_error }

    context 'when description is present' do
      let(:recording) { create(:recording, description: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(description).to be_truthy }
    end

    context 'when description is null' do
      let(:recording) { create(:recording, description: nil) }

      it { expect(description).to be_truthy }
    end
  end

  describe '#always_present_description_text' do
    subject(:description) { recording.always_present_description_text }

    it { expect { description }.not_to raise_error }

    context 'when description is present' do
      let(:recording) { create(:recording, description: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(description).to be_truthy }
    end

    context 'when description is null' do
      let(:recording) { create(:recording, description: nil) }

      it { expect(description).to be_truthy }
    end
  end

  describe '#description_text' do
    subject(:description) { recording.description_text }

    it { expect { description }.not_to raise_error }

    context 'when description is null' do
      let(:recording) { create(:recording, description: nil) }

      it { expect { description }.not_to raise_error }
    end

    context 'when description is empty html' do
      let(:recording) { create(:recording, description: '<p></p>') }

      it { expect { description }.not_to raise_error }
    end
  end

  describe '#share_title' do
    subject(:title) { recording.share_title }

    it { expect { title }.not_to raise_error }

    context 'when title is present' do
      let(:recording) { create(:recording, title: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(title).to be_truthy }
    end

    context 'when title is null' do
      let(:recording) { create(:recording, title: nil) }

      it { expect(title).to be_truthy }
    end
  end

  describe '#share_description' do
    subject(:description) { recording.share_description }

    it { expect { description }.not_to raise_error }

    context 'when description is present' do
      let(:recording) { create(:recording, description: Forgery(:lorem_ipsum).words(3, random: true)) }

      it { expect(description).to be_truthy }
    end

    context 'when description is null' do
      let(:recording) { create(:recording, description: nil) }

      it { expect(description).to be_truthy }
    end
  end

  describe '#processing?' do
    let(:recording) { build(:recording, status: described_class.statuses.keys.sample) }

    it { expect { recording.processing? }.not_to raise_error }

    context 'when status is processing' do
      let(:recording) { build(:recording, status: %i[ready_to_tr transcoding transcoded].sample) }

      it { expect(recording).to be_processing }
    end

    context 'when status is not processing' do
      let(:recording) { build(:recording, status: (described_class.statuses.keys.map(&:to_sym) - %i[ready_to_tr transcoding transcoded]).sample) }

      it { expect(recording).not_to be_processing }
    end
  end

  describe '#unique_view_group_start_at' do
    let(:recording) { build(:recording) }

    it { expect { recording.unique_view_group_start_at }.not_to raise_error }
  end
end
