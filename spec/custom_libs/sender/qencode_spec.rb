# frozen_string_literal: true

require 'spec_helper'

describe Sender::Qencode do
  let(:client) { described_class.client }
  let(:task_token) { '9a06b338532f5467844d3f45a1121fbd' } # do not change, VCR cassette contains status response for this task token
  let(:video) { create(:video_original_verified) }
  let(:encode_params) do
    {
      url: '',
      video_id: video.id,
      s3_preview_path: 's3_preview_path',
      s3_main_path: 's3_main_path',
      start_time: video.crop_seconds.to_i,
      duration: video.cropped_duration&.fdiv(1000) || video.duration.fdiv(1000),
      width: video.width,
      height: video.height
    }
  end

  before do
    VCR.insert_cassette('qencode')
  end

  describe '#access_token' do
    it { expect { client.access_token }.not_to raise_error }

    it { expect(client.access_token).to be_truthy }
  end

  describe '#create_task' do
    it { expect { client.create_task }.not_to raise_error }

    it { expect(client.create_task).to be_truthy }
  end

  describe '#start_encode2' do
    it { expect { client.start_encode2(encode_params) }.not_to raise_error }

    it { expect(client.start_encode2(encode_params)).to be_truthy }

    context 'when qencode service is suspended' do
      before do
        VCR.eject_cassette
        VCR.insert_cassette('qencode_suspended', record: :none)
      end

      it { expect { client.start_encode2(encode_params) }.to raise_error ::Qencode::Errors::ServiceSuspendedError }
    end
  end

  describe '#statuses' do
    it { expect { client.statuses(task_token) }.not_to raise_error }

    it { expect(client.statuses(task_token)).to be_truthy }
  end

  describe '#status' do
    it { expect { client.status(task_token) }.not_to raise_error }

    it { expect(client.status(task_token)).to be_truthy }
  end

  describe '#request' do
    let(:request_params) do
      {
        path: '/v1/access_token',
        body: { api_key: 'qencode_api_key' }
      }
    end

    it { expect { client.request(request_params) }.not_to raise_error }

    it { expect(client.request(request_params)).to be_truthy }
  end
end
