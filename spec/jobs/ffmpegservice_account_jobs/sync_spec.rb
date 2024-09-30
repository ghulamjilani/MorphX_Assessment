# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe FfmpegserviceAccountJobs::Sync do
  let(:wa) { create(:ffmpegservice_account) }
  let(:random_transcoder) { Sender::FfmpegserviceSandbox.new(path: '', method: '').default_transcoder[:transcoder] }
  let(:client) { instance_double(Sender::Ffmpegservice) }

  describe '#perform' do
    context 'when no changes' do
      it { expect { described_class.new.perform(wa.id) }.not_to raise_error }

      it do
        expect do
          described_class.new.perform(wa.id)
          wa.reload
        end.not_to change(wa, :stream_name)
      end
    end

    context 'when changes present' do
      before do
        allow(Sender::Ffmpegservice).to receive(:new).and_return(client)
        allow(client).to receive(:get_transcoder).and_return(random_transcoder)
      end

      it do
        expect do
          described_class.new.perform(wa.id)
          wa.reload
        end.to change(wa, :stream_name)
      end
    end
  end
end
