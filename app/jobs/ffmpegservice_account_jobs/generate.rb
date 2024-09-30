# frozen_string_literal: true

module FfmpegserviceAccountJobs
  # Creates pool of unassigned ffmpegservice accounts of each kind: rtmp, rtsp and webrtc, both passthrough and transcoded
  class Generate < ApplicationJob
    def perform
      pool_size = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :pool_size) || 100
      protocols = %i[rtmp rtsp]
      transcoder_types = %i[passthrough transcoded]
      protocols.each do |protocol|
        transcoder_types.each do |transcoder_type|
          if FfmpegserviceAccount.not_assigned.where(transcoder_type: transcoder_type, protocol: protocol).count < pool_size
            FfmpegserviceAccountJobs::Generate.create_account(transcoder_type: transcoder_type, protocol: protocol)
            return
          end
        end
      end

      if FfmpegserviceAccount.webrtc.not_assigned.count < pool_size
        FfmpegserviceAccountJobs::Generate.create_webrtc_livestream
      end
    end

    def self.create_account(transcoder_type:, protocol:, sandbox: nil)
      if protocol.to_sym == :webrtc
        create_webrtc_livestream(sandbox)
      else
        create_livestream(transcoder_type: transcoder_type, protocol: protocol, sandbox: sandbox)
      end
    end

    def self.create_livestream(transcoder_type:, protocol:, sandbox: nil)
      sandbox = (sandbox.nil? ? !Rails.env.production? : sandbox)
      client = Sender::Ffmpegservice.client(sandbox: sandbox)

      delivery_method = (protocol.to_sym == :rtsp) ? :pull : :push

      livestream = client.create_live_stream(
        params: {
          transcoder_type: transcoder_type,
          delivery_method: delivery_method,
          name: FfmpegserviceAccount.new.transcoder_name
        }
      )
      return unless livestream

      idle_timeout = client.update_transcoder(transcoder: { idle_timeout: 7200 }) ? 7200 : 1200
      info = livestream[:source_connection_information]

      FfmpegserviceAccount.create! do |wa|
        wa.server = info[:primary_server]
        wa.port = info[:host_port]
        wa.stream_name = info[:stream_name]
        wa.authentication = !info[:disable_authentication]
        wa.username = info[:username]
        wa.password = info[:password]
        wa.hls_url = livestream[:player_hls_playback_url]
        wa.stream_status = 'off'
        wa.stream_id = livestream[:id]
        wa.sandbox = sandbox
        wa.transcoder_type = livestream[:transcoder_type]
        wa.delivery_method = livestream[:delivery_method]
        wa.name = livestream[:name]
        wa.idle_timeout = idle_timeout
        wa.protocol = protocol
        wa.application_name = info[:application_name]
        wa.playback_stream_name = livestream[:playback_stream_name]
      end
    end

    def self.create_webrtc_livestream(sandbox = nil)
      sandbox = (sandbox.nil? ? !Rails.env.production? : sandbox)
      client = Sender::Ffmpegservice.client(sandbox: sandbox)

      livestream = client.create_live_stream(
        params: {
          aspect_ratio_height: 720,
          aspect_ratio_width: 1280,
          transcoder_type: 'transcoded',
          delivery_method: :push,
          name: "#{FfmpegserviceAccount.new.transcoder_name} WebRTC",
          disable_authentication: true,
          encoder: :other_webrtc,
          delivery_protocols: %w[hls webrtc rtmp],
          vod_stream: !sandbox
        }
      )
      return unless livestream

      idle_timeout = client.update_transcoder(transcoder: { idle_timeout: 7200 }) ? 7200 : 1200
      info = livestream[:source_connection_information]

      ffmpegservice_account = FfmpegserviceAccount.create! do |wa|
        wa.server = info[:primary_server]
        wa.port = info[:host_port]
        wa.stream_name = info[:stream_name]
        wa.authentication = !info[:disable_authentication]
        wa.username = info[:username]
        wa.password = info[:password]
        wa.hls_url = livestream[:player_hls_playback_url]
        wa.stream_status = 'off'
        wa.stream_id = livestream[:id]
        wa.sandbox = sandbox
        wa.transcoder_type = livestream[:transcoder_type]
        wa.delivery_method = livestream[:delivery_method]
        wa.name = livestream[:name]
        wa.idle_timeout = idle_timeout
        wa.protocol = :webrtc
        wa.application_name = info[:application_name]
        wa.playback_stream_name = livestream[:playback_stream_name]
        wa.sdp_url = info[:sdp_url]
      end

      transcoder = client.get_transcoder
      transcoder[:outputs].reject { |output| output[:name] =~ /WebRTC|(1280 x 720)/ }.pluck(:id).each do |output_id|
        client.delete_transcoder_output(output_id)
      end

      ffmpegservice_account
    end

    def self.create_webrtc_transcoder_passthrough(sandbox: nil)
      sandbox = (sandbox.nil? ? !Rails.env.production? : sandbox)
      client = Sender::Ffmpegservice.client(sandbox: sandbox)

      transcoder = client.create_transcoder(
        params: {
          protocol: :webrtc,
          delivery_method: :push,
          disable_authentication: true,
          transcoder_type: :passthrough,
          name: FfmpegserviceAccount.new.transcoder_name,
          idle_timeout: 1200,
          properties: [
            {
              key: :mp4,
              section: :recording,
              value: true
            },
            {
              key: :hls,
              section: :vod_stream,
              value: true
            }
          ]
        }
      )
      return unless transcoder

      fastly = client.create_stream_target_fastly(transcoder[:name])
      output_id = transcoder.dig(:outputs, 0, :id)
      return unless fastly && output_id

      response = client.create_output_stream_target(transcoder_id: transcoder[:id], output_id: output_id,
                                                    stream_target_id: fastly[:id])
      transcoder = client.update_transcoder(transcoder: {
                                              properties: [
                                                {
                                                  key: :record,
                                                  section: :output,
                                                  value: output_id
                                                }
                                              ]
                                            },
                                            transcoder_id: transcoder[:id])

      hls_url = fastly.dig(:playback_urls, :hls, 0, :url) || transcoder.dig(:direct_playback_urls, :hls, 0, :url)

      FfmpegserviceAccount.create! do |wa|
        wa.stream_name = transcoder[:stream_name]
        wa.hls_url = hls_url
        wa.stream_status = 'off'
        wa.stream_id = transcoder[:id]
        wa.sandbox = sandbox
        wa.transcoder_type = transcoder[:transcoder_type]
        wa.delivery_method = transcoder[:delivery_method]
        wa.name = transcoder[:name]
        wa.idle_timeout = transcoder[:idle_timeout]
        wa.sdp_url = "wss://#{transcoder[:domain_name]}/webrtc-session.json"
        wa.playback_stream_name = transcoder[:playback_stream_name]
        wa.application_name = transcoder[:application_name]
        wa.protocol = transcoder[:protocol]
        wa.current_service = :webrtc
      end
    end
  end
end
