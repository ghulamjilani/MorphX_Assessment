# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe FfmpegserviceAccountJobs::Generate do
  describe '#perform' do
    it { expect { Sidekiq::Testing.inline! { described_class.perform_async } }.not_to raise_error }
  end

  describe '.create_account' do
    transcoder_types = %i[passthrough transcoded]
    protocols = %i[rtmp rtsp]
    transcoder_types.each do |transcoder_type|
      protocols.each do |protocol|
        it {
          expect do
            Sidekiq::Testing.inline! do
              described_class.create_account(transcoder_type: transcoder_type, protocol: protocol)
            end
          end.not_to raise_error
        }
      end
    end

    it {
      expect do
        Sidekiq::Testing.inline! do
          described_class.create_account(transcoder_type: :transcoded, protocol: :webrtc)
        end
      end.not_to raise_error
    }
  end
end
