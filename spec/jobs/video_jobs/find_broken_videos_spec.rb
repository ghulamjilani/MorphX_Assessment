# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe VideoJobs::FindBrokenVideos do
  let(:video) { create(:video_published, hls_main: '/1/playlist.m3u8') }

  before do
    stub_request(:any, /.*chat.webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  context 'when given no id' do
    before do
      video
    end

    it 'enqueues jobs' do
      expect do
        described_class.new.perform
      end.to change(described_class.jobs, :size)
    end
  end

  context 'when given id' do
    context 'when video hls_url works' do
      before do
        quoted_cdn_host = Regexp.quote ENV['HWCDN'].to_s
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*playlist\.m3u8")).to_return(status: 200,
                                                                                         body: 'video.m3u8', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*video\.m3u8")).to_return(status: 200,
                                                                                      body: 'video_4/0.ts', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*\.ts")).to_return(status: 200, body: '', headers: {})
      end

      it 'does not fail' do
        expect { Sidekiq::Testing.inline! { described_class.perform_async(video.id) } }.not_to raise_error
      end
    end

    context 'when video hls_url is empty' do
      let(:video) { create(:video_published, hls_main: nil) }

      before do
        quoted_cdn_host = Regexp.quote ENV['HWCDN'].to_s
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*playlist\.m3u8")).to_return(status: 404,
                                                                                         body: 'video.m3u8', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*video\.m3u8")).to_return(status: 404,
                                                                                      body: 'video_4/0.ts', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*\.ts")).to_return(status: 404, body: '', headers: {})
      end

      it 'does not fail' do
        allow(Airbrake).to receive(:notify)
        expect { Sidekiq::Testing.inline! { described_class.perform_async(video.id) } }.not_to raise_error
      end
    end

    context 'when video hls_url does not work' do
      before do
        quoted_cdn_host = Regexp.quote ENV['HWCDN'].to_s
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*playlist\.m3u8")).to_return(status: 404,
                                                                                         body: 'video.m3u8', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*video\.m3u8")).to_return(status: 404,
                                                                                      body: 'video_4/0.ts', headers: {})
        stub_request(:any, Regexp.new(".*#{quoted_cdn_host}.*\.ts")).to_return(status: 404, body: '', headers: {})
      end

      it 'does not fail' do
        allow(Airbrake).to receive(:notify)
        expect { Sidekiq::Testing.inline! { described_class.perform_async(video.id) } }.not_to raise_error
      end
    end
  end
end
