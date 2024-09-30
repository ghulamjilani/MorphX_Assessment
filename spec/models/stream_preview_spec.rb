# frozen_string_literal: true
require 'spec_helper'

describe StreamPreview do
  let(:stream_preview) { create(:stream_preview) }

  describe 'validations' do
    it 'checks presence of organization' do
      stream_preview = build(:stream_preview, organization: nil)
      stream_preview.valid?
      expect(stream_preview.errors[:organization_id]).not_to be_nil
    end

    it 'checks presence of ffmpegservice_account' do
      stream_preview = build(:stream_preview, ffmpegservice_account: nil)
      stream_preview.valid?
      expect(stream_preview.errors[:ffmpegservice_account_id]).not_to be_nil
    end
  end

  describe '#end_at' do
    it 'works' do
      expect(stream_preview.end_at).to be_truthy
    end
  end

  describe '#stopped?' do
    context 'when stopped' do
      let(:stream_preview) { create(:stream_preview_stopped) }

      it 'returns true' do
        expect(stream_preview.stopped?).to eq true
      end
    end

    context 'when not stopped' do
      it 'returns false' do
        expect(stream_preview.stopped?).to eq false
      end
    end
  end

  describe '#ended?' do
    context 'when stopped' do
      let(:stream_preview) { create(:stream_preview_stopped) }

      it 'returns true' do
        expect(stream_preview.ended?).to eq true
      end
    end

    context 'when passed' do
      let(:stream_preview) { create(:stream_preview_passed) }

      it 'returns true' do
        expect(stream_preview.ended?).to eq true
      end
    end

    context 'when running' do
      it 'returns false' do
        expect(stream_preview.ended?).to eq false
      end
    end
  end

  describe '#stop!' do
    it 'sets ffmpegservice account stream status to off' do
      stream_preview.ffmpegservice_account.stream_up!
      expect { stream_preview.stop! }.to change { stream_preview.ffmpegservice_account.stream_off? }.from(false).to(true)
    end
  end
end
