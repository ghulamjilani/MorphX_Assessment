# frozen_string_literal: true

# froze_string_literal: true
module Sender
  class FfmpegserviceSandbox
    def initialize(path:, method:, body: nil, ffmpegservice_account: nil)
      @path = path
      @method = method
      @body = begin
        JSON.parse(body)
      rescue StandardError
        {}
      end.symbolize_keys
      @ffmpegservice_account = ffmpegservice_account
    end

    def response
      case @path
      when livestreams_regexp
        case @method.to_sym
        when :post
          default_livestream
        else
          { live_streams: [] }
        end
      when livestream_regexp
        id = @path.match(livestream_regexp)[1]
        default_livestream(stream_id: id)
      when transcoders_regexp
        case @method.to_sym
        when :post
          default_transcoder
        else
          { transcoders: [] }
        end
      when livestream_state_regexp
        { live_stream: { ip_address: '0.0.0.0', state: 'started', uptime_id: SecureRandom.alphanumeric(8).downcase } }
      when livestream_stats_regexp
        { live_stream: { connected: { value: 'Yes' } } }
      when livestream_action_regexp
        match = @path.match(livestream_action_regexp)
        action = match.to_a[2]
        state = case action
                when 'start'
                  'starting'
                when 'stop'
                  'stopping'
                when 'reset'
                  'resetting'
                else
                  'started'
                end
        { live_stream: { state: state } }
      when transcoder_regexp
        id = @path.match(transcoder_regexp)[1]
        default_transcoder(stream_id: id)
      when transcoder_action_regexp
        match = @path.match(transcoder_action_regexp)
        action = match.to_a[2]
        state = case action
                when 'start'
                  'starting'
                when 'stop'
                  'stopping'
                when 'reset'
                  'resetting'
                else
                  'started'
                end
        { transcoder: { state: state, uptime_id: SecureRandom.alphanumeric(8).downcase } }
      when transcoder_state_regexp
        { transcoder: { ip_address: '0.0.0.0', state: 'started', uptime_id: SecureRandom.alphanumeric(8).downcase } }
      when transcoder_stats_regexp
        { live_stream: { connected: { value: 'Yes' } } }
      when transcoder_schedules_regexp
        { schedules: [] }
      when recordings_regexp
        { recordings: [] }
      when recording_regexp
        case @method.to_sym
        when :delete
          { recordings: [] }
        else
          recording_response
        end
      when stream_targets_fastly_regexp
        case @method.to_sym
        when :post
          stream_target_fastly_response
        else
          { stream_targets_fastly: [] }
        end
      when stream_target_fastly_regexp
        stream_target_fastly_response
      else
        {}
      end.symbolize_keys.deep_merge(@body).with_indifferent_access
    end

    def livestreams_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/live_streams')}(\/)?$")
    end

    def livestream_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/live_streams/')}([a-z0-9]+)(\/)?$")
    end

    def livestream_state_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/live_streams/')}([a-z0-9]+)\/state(\/)?$")
    end

    def livestream_stats_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/live_streams/')}([a-z0-9]+)\/stats(\/)?$")
    end

    def livestream_action_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/live_streams/')}([a-z0-9]+)\/(start|stop|reset)(\/)?$")
    end

    def transcoders_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders')}(\/)?$")
    end

    def transcoder_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders/')}([a-z0-9]+)(\/)?$")
    end

    def transcoder_action_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders/')}([a-z0-9]+)\/(start|stop|reset)(\/)?$")
    end

    def transcoder_state_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders/')}([a-z0-9]+)\/state(\/)?$")
    end

    def transcoder_stats_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/analytics/ingest/live_streams/')}([a-z0-9]+)(\/)?$")
    end

    def transcoder_schedules_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders/')}[a-z0-9]+\/schedules(\/)?$")
    end

    def transcoder_schedule_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/transcoders/')}[a-z0-9]+\/schedules\/([a-z0-9]+)(\/)?$")
    end

    def recordings_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/recordings')}(\/)?$")
    end

    def recording_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/recordings/')}([a-z0-9]+)(\/)?$")
    end

    def stream_targets_fastly_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/stream_targets/fastly')}(\/)?$")
    end

    def stream_target_fastly_regexp
      Regexp.new("#{Regexp.quote('/api/v1.11/stream_targets/fastly/')}([a-z0-9]+)(\/)?$")
    end

    def default_transcoder(stream_id: nil)
      stream_target_id = SecureRandom.alphanumeric(8).downcase
      @ffmpegservice_account ||= default_ffmpegservice_account(stream_id: stream_id)
      domain_name = begin
        @ffmpegservice_account.sdp_url.match(%r{wss://(.*)/webrtc-session.json})[1]
      rescue StandardError
        default_domain
      end

      {
        transcoder: {
          id: @ffmpegservice_account.stream_id,
          name: @ffmpegservice_account.transcoder_name,
          transcoder_type: @ffmpegservice_account.transcoder_type,
          billing_mode: 'pay_as_you_go',
          broadcast_location: 'us_central_iowa',
          closed_caption_type: 'none',
          protocol: @ffmpegservice_account.protocol,
          delivery_method: @ffmpegservice_account.delivery_method,
          source_port: 1935,
          domain_name: domain_name,
          application_name: @ffmpegservice_account.application_name,
          stream_name: @ffmpegservice_account.stream_name,
          playback_stream_name: @ffmpegservice_account.playback_stream_name,
          delivery_protocols: ['hls'],
          buffer_size: 4000,
          low_latency: false,
          stream_smoother: false,
          idle_timeout: 7200,
          play_maximum_connections: 10,
          disable_authentication: !@ffmpegservice_account.authentication,
          username: @ffmpegservice_account.username,
          password: @ffmpegservice_account.password,
          watermark: false,
          created_at: '2020-04-27T15:40:02.000Z',
          updated_at: '2020-12-16T19:22:02.000Z',
          direct_playback_urls: {
            hls: [
              {
                name: 'default',
                url: @ffmpegservice_account.hls_url
              }
            ]
          },
          outputs: [
            {
              id: SecureRandom.alphanumeric(8).downcase,
              name: 'Standard Output: Video + Audio',
              transcoder_id: @ffmpegservice_account.stream_id,
              video_codec: 'passthrough',
              audio_codec: 'passthrough',
              aspect_ratio_width: 1920,
              aspect_ratio_height: 1080,
              bitrate_video: 4000,
              bitrate_audio: 128,
              h264_profile: 'high',
              framerate_reduction: '0',
              keyframes: 'follow_source',
              created_at: '2020-04-27T15:40:03.000Z',
              updated_at: '2020-04-27T15:40:03.000Z',
              output_stream_targets: [
                {
                  id: SecureRandom.alphanumeric(8).downcase,
                  stream_target_id: stream_target_id,
                  use_stream_target_backup_url: false,
                  stream_target: {
                    id: stream_target_id,
                    name: '[ENV:PR];2020-04-27 15:40:02 / Stream Target',
                    type: 'fastly',
                    created_at: '2020-04-27T15:40:03.000Z',
                    updated_at: '2020-04-27T15:40:03.000Z'
                  }
                }
              ]
            }
          ]
        }
      }
    end

    def default_livestream(stream_id: nil)
      stream_target_id = SecureRandom.alphanumeric(8).downcase
      @ffmpegservice_account ||= default_ffmpegservice_account(stream_id: stream_id)
      domain_name = begin
        @ffmpegservice_account.sdp_url.match(%r{wss://(.*)/webrtc-session.json})[1]
      rescue StandardError
        default_domain
      end

      {
        live_stream: {
          id: @ffmpegservice_account.stream_id,
          name: @ffmpegservice_account.transcoder_name,
          transcoder_type: @ffmpegservice_account.transcoder_type,
          billing_mode: 'pay_as_you_go',
          broadcast_location: 'us_west_california',
          vod_stream: false,
          recording: true,
          closed_caption_type: 'none',
          low_latency: false,
          encoder: 'other_webrtc',
          delivery_method: @ffmpegservice_account.delivery_method,
          playback_stream_name: @ffmpegservice_account.playback_stream_name,
          target_delivery_protocol: 'hls-https',
          use_stream_source: false,
          aspect_ratio_width: 1920,
          aspect_ratio_height: 1080,
          delivery_protocols: ['hls'],
          source_connection_information: {
            stream_name: @ffmpegservice_account.stream_name,
            primary_server: @ffmpegservice_account.server,
            host_port: @ffmpegservice_account.port,
            sdp_url: @ffmpegservice_account.sdp_url,
            application_name: @ffmpegservice_account.application_name,
            username: @ffmpegservice_account.username,
            password: @ffmpegservice_account.password
          },
          player_id: SecureRandom.alphanumeric(8).downcase,
          player_type: 'original_html5',
          player_responsive: false,
          player_width: 640,
          player_countdown: false,
          player_embed_code: "\u003cdiv id='ffmpegservice_player'\u003e\u003c/div\u003e\n\u003cscript id='player_embed' src='//player.cloud.ffmpegservice.com/hosted/klf12jfc/ffmpegservice.js' type='text/javascript'\u003e\u003c/script\u003e\n",
          player_hls_playback_url: 'https://cdn3.ffmpegservice.com/1/ZEk2cHJxWmxDbURS/Z1NPS0lo/hls/live/playlist.m3u8',
          hosted_page: false,
          stream_targets: [{
            id: SecureRandom.alphanumeric(8).downcase
          }],
          direct_playback_urls: {
            hls: [{
              name: 'default',
              url: @ffmpegservice_account.sdp_url
            }]
          },
          created_at: '2021-05-18T13:35:22.000Z',
          updated_at: '2021-05-21T15:27:09.000Z'
        }
      }
    end

    def default_ffmpegservice_account(stream_id: nil)
      default_app_name = "app-#{SecureRandom.alphanumeric(4).downcase}"
      FfmpegserviceAccount.new(
        stream_id: (stream_id || SecureRandom.alphanumeric(8).downcase),
        protocol: 'rtmp',
        delivery_method: 'push',
        transcoder_type: 'passthrough',
        application_name: default_app_name,
        sdp_url: "wss://#{default_domain}/webrtc-session.json",
        playback_stream_name: SecureRandom.alphanumeric(8).downcase,
        stream_name: SecureRandom.alphanumeric(8).downcase,
        server: "rtmp://#{default_domain}/#{default_app_name}",
        port: '1935',
        username: SecureRandom.alphanumeric(8).downcase,
        password: SecureRandom.alphanumeric(8).downcase,
        hls_url: "https://#{default_domain}/#{default_app_name}/ngrp:06aff8d4_all/playlist.m3u8",
        host_ip: '0.0.0.0'
      )
    end

    def default_domain
      @default_domain ||= "#{SecureRandom.alphanumeric(6).downcase}.entrypoint.cloud.ffmpegservice.com"
    end

    def recording_response
      {
        recording: {
          created_at: '2020-01-29T17:16:21.993Z',
          download_url: 'https://s3.amazonaws.com/prod-wse-recordings/transcoder_035163/64886_00a613bf@367500.stream.0.mp4',
          duration: 362_905,
          file_name: '00a613bf@367500.stream.0.mp4',
          file_size: 53_113_429,
          id: SecureRandom.alphanumeric(8).downcase,
          reason: '',
          starts_at: '2020-02-01T00:00:00.000Z',
          transcoding_uptime_id: @transcoding_uptime_id || SecureRandom.alphanumeric(8).downcase,
          state: 'completed',
          transcoder_id: @ffmpegservice_account&.stream_id,
          transcoder_name: @ffmpegservice_account&.name || 'My Camera',
          updated_at: '2020-01-30T17:22:20.993Z'
        }
      }
    end

    def stream_target_fastly_response
      {
        stream_target_fastly: {
          id: SecureRandom.alphanumeric(8).downcase,
          name: 'My Ffmpegservice CDN on Fastly Stream Target',
          state: 'activated',
          stream_name: @ffmpegservice_account&.stream_name,
          playback_urls: {},
          token_auth_enabled: false,
          token_auth_playlist_only: false,
          geoblock_enabled: true,
          geoblock_by_location: 'allow',
          geoblock_country_codes: 'DE, US',
          geoblock_ip_override: 'deny',
          geblock_ip_addresses: '77.12.34.567, 78.23.45.678',
          force_ssl_playback: false,
          created_at: '2020-01-28T17:16:22.086Z',
          updated_at: '2020-01-30T15:33:43.086Z'
        }
      }
    end
  end
end
