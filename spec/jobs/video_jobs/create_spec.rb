# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe VideoJobs::Create do
  before do
    stub_request(:any, /.*chat.webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  it 'does not fail' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async } }.not_to raise_error
  end

  context 'when new videos found' do
    let(:client) { instance_double(Sender::Ffmpegservice) }
    let(:uptime) { create(:transcoder_uptime) }
    let(:wa) { create(:ffmpegservice_account) }

    let(:recordings_response) do
      [
        {
          created_at: '2020-01-29T17:16:21.993Z',
          download_url: 'https://s3.amazonaws.com/prod-wse-recordings/transcoder_035163/64886_00a613bf@367500.stream.0.mp4',
          duration: 362_905,
          file_name: '00a613bf@367500.stream.0.mp4',
          file_size: 53_113_429,
          id: SecureRandom.alphanumeric(8).downcase,
          reason: '',
          starts_at: '2020-02-01T00:00:00.000Z',
          transcoding_uptime_id: uptime.uptime_id,
          state: 'completed',
          transcoder_id: wa.stream_id,
          transcoder_name: wa.name,
          updated_at: '2020-01-30T17:22:20.993Z'
        }
      ]
    end

    before do
      allow(Sender::Ffmpegservice).to receive(:client).and_return(client)
      allow(client).to receive(:recordings).and_return(recordings_response)
      allow(client).to receive(:recording).and_return(Sender::FfmpegserviceSandbox.new(path: '', method: :get).recording_response[:recording])
    end

    it 'creates new videos' do
      expect { Sidekiq::Testing.inline! { described_class.perform_async } }.to change(Video, :count)
    end
  end
end
