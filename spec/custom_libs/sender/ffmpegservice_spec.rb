# frozen_string_literal: true

require 'spec_helper'

describe Sender::Ffmpegservice do
  let(:ffmpegservice_account) { build(:ffmpegservice_account) }
  let(:livestream_params) do
    {
      delivery_method: %w[push pull].sample,
      transcoder_type: %w[passthrough transcoded].sample,
      name: Forgery(:lorem_ipsum).words(3, random: true)
    }
  end
  let(:transcoder_params) do
    {
      idle_timeout: 7200,
      disable_authentication: true
    }
  end
  let(:stream_id) { SecureRandom.alphanumeric(8).downcase }
  let(:output_id) { SecureRandom.alphanumeric(8).downcase }
  let(:stream_target_id) { SecureRandom.alphanumeric(8).downcase }
  let(:from) { 20.seconds.ago }
  let(:to) { 5.seconds.ago }
  let(:stop_at) { 15.minutes.from_now }

  context 'when client uses existing ffmpegservice_account' do
    let(:client) { described_class.client(account: ffmpegservice_account) }

    describe '#create_live_stream' do
      it { expect { client.create_live_stream(params: livestream_params) }.not_to raise_error }

      it { expect(client.create_live_stream(params: livestream_params)).to be_truthy }
    end

    describe '#update_live_stream' do
      it { expect { client.update_live_stream(live_stream: livestream_params) }.not_to raise_error }

      it { expect(client.update_live_stream(live_stream: livestream_params)).to be_truthy }
    end

    describe '#live_streams' do
      it { expect { client.live_streams }.not_to raise_error }

      it { expect(client.live_streams).to be_truthy }
    end

    describe '#live_stream' do
      it { expect { client.live_stream }.not_to raise_error }

      it { expect(client.live_stream).to be_truthy }
    end

    describe '#start_stream' do
      it { expect { client.start_stream }.not_to raise_error }

      it { expect(client.start_stream).to be_truthy }
    end

    describe '#reset_stream' do
      it { expect { client.reset_stream }.not_to raise_error }

      it { expect(client.reset_stream).to be_truthy }
    end

    describe '#stop_stream' do
      it { expect { client.stop_stream }.not_to raise_error }

      it { expect(client.stop_stream).to be_truthy }
    end

    describe '#delete_live_stream' do
      it { expect { client.delete_live_stream }.not_to raise_error }

      it { expect(client.delete_live_stream).to be_truthy }
    end

    describe '#start_transcoder' do
      it { expect { client.start_transcoder }.not_to raise_error }

      it { expect(client.start_transcoder).to be_truthy }
    end

    describe '#stop_transcoder' do
      it { expect { client.stop_transcoder }.not_to raise_error }

      it { expect(client.stop_transcoder).to be_truthy }
    end

    describe '#reset_transcoder' do
      it { expect { client.reset_transcoder }.not_to raise_error }

      it { expect(client.reset_transcoder).to be_truthy }
    end

    describe '#update_transcoder' do
      it { expect { client.update_transcoder(transcoder: transcoder_params) }.not_to raise_error }

      it { expect(client.update_transcoder(transcoder: transcoder_params)).to be_truthy }
    end

    describe '#create_transcoder' do
      it { expect { client.create_transcoder(params: transcoder_params) }.not_to raise_error }

      it { expect(client.create_transcoder(params: transcoder_params)).to be_truthy }
    end

    describe '#get_transcoder' do
      it { expect { client.get_transcoder }.not_to raise_error }

      it { expect(client.get_transcoder).to be_truthy }
    end

    describe '#state_stream' do
      it { expect { client.state_stream }.not_to raise_error }

      it { expect(client.state_stream).to be_truthy }
    end

    describe '#state_transcoder' do
      it { expect { client.state_transcoder }.not_to raise_error }

      it { expect(client.state_transcoder).to be_truthy }
    end

    describe '#stats_stream' do
      it { expect { client.stats_stream }.not_to raise_error }

      it { expect(client.stats_stream).to be_truthy }
    end

    describe '#stream_active?' do
      it { expect { client.stream_active? }.not_to raise_error }

      it { expect(client.stream_active?).to be(true) }
    end

    describe '#stats_transcoder' do
      it { expect { client.stats_transcoder }.not_to raise_error }

      it { expect(client.stats_transcoder).to be_truthy }
    end

    describe '#transcoder_active?' do
      it { expect { client.transcoder_active? }.not_to raise_error }

      it { expect(client.transcoder_active?).to be(true) }
    end

    describe '#delete_transcoder' do
      it { expect { client.delete_transcoder }.not_to raise_error }

      it { expect(client.delete_transcoder).to be_truthy }
    end

    describe '#recordings' do
      it { expect { client.recordings }.not_to raise_error }

      it { expect(client.recordings).to be_truthy }
    end

    describe '#recording' do
      it { expect { client.recording(stream_id) }.not_to raise_error }

      it { expect(client.recording(stream_id)).to be_truthy }
    end

    describe '#delete_recording' do
      it { expect { client.delete_recording(stream_id) }.not_to raise_error }

      it { expect(client.delete_recording(stream_id)).to be_truthy }
    end

    describe '#transcoder_schedules' do
      it { expect { client.transcoder_schedules }.not_to raise_error }

      it { expect(client.transcoder_schedules).to be_truthy }
    end

    describe '#create_schedule_stop' do
      it { expect { client.create_schedule_stop(stream_id, stop_at) }.not_to raise_error }

      it { expect(client.create_schedule_stop(stream_id, stop_at)).to be_truthy }
    end

    describe '#delete_schedule' do
      it { expect { client.delete_schedule(stream_id) }.not_to raise_error }

      it { expect(client.delete_schedule(stream_id)).to be_truthy }
    end

    describe '#transcoders_usage' do
      it { expect { client.transcoders_usage(from, to) }.not_to raise_error }

      it { expect(client.transcoders_usage(from, to)).to be_truthy }
    end

    describe '#create_stream_target_fastly' do
      it { expect { client.create_stream_target_fastly(ffmpegservice_account.name) }.not_to raise_error }

      it { expect(client.create_stream_target_fastly(ffmpegservice_account.name)).to be_truthy }
    end

    describe '#stream_target_fastly' do
      it { expect { client.stream_target_fastly(stream_id) }.not_to raise_error }

      it { expect(client.stream_target_fastly(stream_id)).to be_truthy }
    end

    describe '#create_output' do
      it { expect { client.create_output }.not_to raise_error }

      it { expect(client.create_output).to be_truthy }
    end

    describe '#delete_transcoder_output' do
      it { expect { client.delete_transcoder_output(output_id) }.not_to raise_error }

      it { expect(client.delete_transcoder_output(output_id)).to be_truthy }
    end

    describe '#create_output_stream_target' do
      it {
        expect do
          client.create_output_stream_target(output_id: output_id, stream_target_id: stream_target_id)
        end.not_to raise_error
      }

      it {
        expect(client.create_output_stream_target(output_id: output_id,
                                                  stream_target_id: stream_target_id)).to be_truthy
      }
    end
  end

  context 'when client uses stream id' do
    let(:client) { described_class.new(sandbox: true, stream_id: ffmpegservice_account.stream_id) }

    describe '#create_live_stream' do
      it { expect { client.create_live_stream(params: livestream_params) }.not_to raise_error }

      it { expect(client.create_live_stream(params: livestream_params)).to be_truthy }
    end

    describe '#update_live_stream' do
      it { expect { client.update_live_stream(live_stream: livestream_params) }.not_to raise_error }

      it { expect(client.update_live_stream(live_stream: livestream_params)).to be_truthy }
    end

    describe '#live_streams' do
      it { expect { client.live_streams }.not_to raise_error }

      it { expect(client.live_streams).to be_truthy }
    end

    describe '#live_stream' do
      it { expect { client.live_stream }.not_to raise_error }

      it { expect(client.live_stream).to be_truthy }
    end

    describe '#start_stream' do
      it { expect { client.start_stream }.not_to raise_error }

      it { expect(client.start_stream).to be_truthy }
    end

    describe '#reset_stream' do
      it { expect { client.reset_stream }.not_to raise_error }

      it { expect(client.reset_stream).to be_truthy }
    end

    describe '#stop_stream' do
      it { expect { client.stop_stream }.not_to raise_error }

      it { expect(client.stop_stream).to be_truthy }
    end

    describe '#delete_live_stream' do
      it { expect { client.delete_live_stream }.not_to raise_error }

      it { expect(client.delete_live_stream).to be_truthy }
    end

    describe '#start_transcoder' do
      it { expect { client.start_transcoder }.not_to raise_error }

      it { expect(client.start_transcoder).to be_truthy }
    end

    describe '#stop_transcoder' do
      it { expect { client.stop_transcoder }.not_to raise_error }

      it { expect(client.stop_transcoder).to be_truthy }
    end

    describe '#reset_transcoder' do
      it { expect { client.reset_transcoder }.not_to raise_error }

      it { expect(client.reset_transcoder).to be_truthy }
    end

    describe '#update_transcoder' do
      it { expect { client.update_transcoder(transcoder: transcoder_params) }.not_to raise_error }

      it { expect(client.update_transcoder(transcoder: transcoder_params)).to be_truthy }
    end

    describe '#create_transcoder' do
      it { expect { client.create_transcoder(params: transcoder_params) }.not_to raise_error }

      it { expect(client.create_transcoder(params: transcoder_params)).to be_truthy }
    end

    describe '#get_transcoder' do
      it { expect { client.get_transcoder }.not_to raise_error }

      it { expect(client.get_transcoder).to be_truthy }
    end

    describe '#state_stream' do
      it { expect { client.state_stream }.not_to raise_error }

      it { expect(client.state_stream).to be_truthy }
    end

    describe '#state_transcoder' do
      it { expect { client.state_transcoder }.not_to raise_error }

      it { expect(client.state_transcoder).to be_truthy }
    end

    describe '#stats_stream' do
      it { expect { client.stats_stream }.not_to raise_error }

      it { expect(client.stats_stream).to be_truthy }
    end

    describe '#stream_active?' do
      it { expect { client.stream_active? }.not_to raise_error }

      it { expect(client.stream_active?).to be(true) }
    end

    describe '#stats_transcoder' do
      it { expect { client.stats_transcoder }.not_to raise_error }

      it { expect(client.stats_transcoder).to be_truthy }
    end

    describe '#transcoder_active?' do
      it { expect { client.transcoder_active? }.not_to raise_error }

      it { expect(client.transcoder_active?).to be(true) }
    end

    describe '#delete_transcoder' do
      it { expect { client.delete_transcoder }.not_to raise_error }

      it { expect(client.delete_transcoder).to be_truthy }
    end

    describe '#recordings' do
      it { expect { client.recordings }.not_to raise_error }

      it { expect(client.recordings).to be_truthy }
    end

    describe '#recording' do
      it { expect { client.recording(stream_id) }.not_to raise_error }

      it { expect(client.recording(stream_id)).to be_truthy }
    end

    describe '#delete_recording' do
      it { expect { client.delete_recording(stream_id) }.not_to raise_error }

      it { expect(client.delete_recording(stream_id)).to be_truthy }
    end

    describe '#transcoder_schedules' do
      it { expect { client.transcoder_schedules }.not_to raise_error }

      it { expect(client.transcoder_schedules).to be_truthy }
    end

    describe '#create_schedule_stop' do
      it { expect { client.create_schedule_stop(stream_id, stop_at) }.not_to raise_error }

      it { expect(client.create_schedule_stop(stream_id, stop_at)).to be_truthy }
    end

    describe '#delete_schedule' do
      it { expect { client.delete_schedule(stream_id) }.not_to raise_error }

      it { expect(client.delete_schedule(stream_id)).to be_truthy }
    end

    describe '#transcoders_usage' do
      it { expect { client.transcoders_usage(from, to) }.not_to raise_error }

      it { expect(client.transcoders_usage(from, to)).to be_truthy }
    end

    describe '#create_stream_target_fastly' do
      it { expect { client.create_stream_target_fastly(ffmpegservice_account.name) }.not_to raise_error }

      it { expect(client.create_stream_target_fastly(ffmpegservice_account.name)).to be_truthy }
    end

    describe '#stream_target_fastly' do
      it { expect { client.stream_target_fastly(stream_id) }.not_to raise_error }

      it { expect(client.stream_target_fastly(stream_id)).to be_truthy }
    end

    describe '#create_output' do
      it { expect { client.create_output }.not_to raise_error }

      it { expect(client.create_output).to be_truthy }
    end

    describe '#delete_transcoder_output' do
      it { expect { client.delete_transcoder_output(output_id) }.not_to raise_error }

      it { expect(client.delete_transcoder_output(output_id)).to be_truthy }
    end

    describe '#create_output_stream_target' do
      it {
        expect do
          client.create_output_stream_target(output_id: output_id, stream_target_id: stream_target_id)
        end.not_to raise_error
      }

      it {
        expect(client.create_output_stream_target(output_id: output_id,
                                                  stream_target_id: stream_target_id)).to be_truthy
      }
    end
  end

  context 'when client does not use stream_id and wa' do
    let(:client) { described_class.new(sandbox: true) }

    describe '#create_live_stream' do
      it { expect { client.create_live_stream(params: livestream_params) }.not_to raise_error }

      it { expect(client.create_live_stream(params: livestream_params)).to be_truthy }
    end

    describe '#update_live_stream' do
      it {
        expect do
          client.update_live_stream(live_stream: livestream_params, stream_id: stream_id)
        end.not_to raise_error
      }

      it { expect(client.update_live_stream(live_stream: livestream_params, stream_id: stream_id)).to be_truthy }
    end

    describe '#live_streams' do
      it { expect { client.live_streams }.not_to raise_error }

      it { expect(client.live_streams).to be_truthy }
    end

    describe '#live_stream' do
      it { expect { client.live_stream(stream_id) }.not_to raise_error }

      it { expect(client.live_stream(stream_id)).to be_truthy }
    end

    describe '#start_stream' do
      it { expect { client.start_stream(stream_id) }.not_to raise_error }

      it { expect(client.start_stream(stream_id)).to be_truthy }
    end

    describe '#reset_stream' do
      it { expect { client.reset_stream(stream_id) }.not_to raise_error }

      it { expect(client.reset_stream(stream_id)).to be_truthy }
    end

    describe '#stop_stream' do
      it { expect { client.stop_stream(stream_id) }.not_to raise_error }

      it { expect(client.stop_stream(stream_id)).to be_truthy }
    end

    describe '#delete_live_stream' do
      it { expect { client.delete_live_stream(stream_id) }.not_to raise_error }

      it { expect(client.delete_live_stream(stream_id)).to be_truthy }
    end

    describe '#start_transcoder' do
      it { expect { client.start_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.start_transcoder(stream_id)).to be_truthy }
    end

    describe '#stop_transcoder' do
      it { expect { client.stop_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.stop_transcoder(stream_id)).to be_truthy }
    end

    describe '#reset_transcoder' do
      it { expect { client.reset_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.reset_transcoder(stream_id)).to be_truthy }
    end

    describe '#update_transcoder' do
      it {
        expect do
          client.update_transcoder(transcoder: transcoder_params, transcoder_id: stream_id)
        end.not_to raise_error
      }

      it { expect(client.update_transcoder(transcoder: transcoder_params, transcoder_id: stream_id)).to be_truthy }
    end

    describe '#create_transcoder' do
      it { expect { client.create_transcoder(params: transcoder_params) }.not_to raise_error }

      it { expect(client.create_transcoder(params: transcoder_params)).to be_truthy }
    end

    describe '#get_transcoder' do
      it { expect { client.get_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.get_transcoder(stream_id)).to be_truthy }
    end

    describe '#state_stream' do
      it { expect { client.state_stream(stream_id) }.not_to raise_error }

      it { expect(client.state_stream(stream_id)).to be_truthy }
    end

    describe '#state_transcoder' do
      it { expect { client.state_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.state_transcoder(stream_id)).to be_truthy }
    end

    describe '#stats_stream' do
      it { expect { client.stats_stream(stream_id) }.not_to raise_error }

      it { expect(client.stats_stream(stream_id)).to be_truthy }
    end

    describe '#stream_active?' do
      it { expect { client.stream_active?(stream_id) }.not_to raise_error }

      it { expect(client.stream_active?(stream_id)).to be(true) }
    end

    describe '#stats_transcoder' do
      it { expect { client.stats_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.stats_transcoder(stream_id)).to be_truthy }
    end

    describe '#transcoder_active?' do
      it { expect { client.transcoder_active?(stream_id) }.not_to raise_error }

      it { expect(client.transcoder_active?(stream_id)).to be(true) }
    end

    describe '#delete_transcoder' do
      it { expect { client.delete_transcoder(stream_id) }.not_to raise_error }

      it { expect(client.delete_transcoder(stream_id)).to be_truthy }
    end

    describe '#recordings' do
      it { expect { client.recordings }.not_to raise_error }

      it { expect(client.recordings).to be_truthy }
    end

    describe '#recording' do
      it { expect { client.recording(stream_id) }.not_to raise_error }

      it { expect(client.recording(stream_id)).to be_truthy }
    end

    describe '#delete_recording' do
      it { expect { client.delete_recording(stream_id) }.not_to raise_error }

      it { expect(client.delete_recording(stream_id)).to be_truthy }
    end

    describe '#transcoder_schedules' do
      it { expect { client.transcoder_schedules(stream_id) }.not_to raise_error }

      it { expect(client.transcoder_schedules(stream_id)).to be_truthy }
    end

    describe '#create_schedule_stop' do
      it { expect { client.create_schedule_stop(stream_id, stop_at) }.not_to raise_error }

      it { expect(client.create_schedule_stop(stream_id, stop_at)).to be_truthy }
    end

    describe '#delete_schedule' do
      it { expect { client.delete_schedule(stream_id) }.not_to raise_error }

      it { expect(client.delete_schedule(stream_id)).to be_truthy }
    end

    describe '#transcoders_usage' do
      it { expect { client.transcoders_usage(from, to) }.not_to raise_error }

      it { expect(client.transcoders_usage(from, to)).to be_truthy }
    end

    describe '#create_stream_target_fastly' do
      it { expect { client.create_stream_target_fastly(ffmpegservice_account.name) }.not_to raise_error }

      it { expect(client.create_stream_target_fastly(ffmpegservice_account.name)).to be_truthy }
    end

    describe '#stream_target_fastly' do
      it { expect { client.stream_target_fastly(stream_id) }.not_to raise_error }

      it { expect(client.stream_target_fastly(stream_id)).to be_truthy }
    end

    describe '#create_output' do
      it { expect { client.create_output(transcoder_id: stream_id) }.not_to raise_error }

      it { expect(client.create_output(transcoder_id: stream_id)).to be_truthy }
    end

    describe '#delete_transcoder_output' do
      it { expect { client.delete_transcoder_output(output_id, stream_id) }.not_to raise_error }

      it { expect(client.delete_transcoder_output(output_id, stream_id)).to be_truthy }
    end

    describe '#create_output_stream_target' do
      it {
        expect do
          client.create_output_stream_target(output_id: output_id, stream_target_id: stream_target_id,
                                             transcoder_id: stream_id)
        end.not_to raise_error
      }

      it {
        expect(client.create_output_stream_target(output_id: output_id, stream_target_id: stream_target_id,
                                                  transcoder_id: stream_id)).to be_truthy
      }
    end
  end
end
