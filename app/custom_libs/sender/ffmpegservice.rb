# frozen_string_literal: true

# https://api.docs.video.ffmpegservice.com/wsc/current/overview/
module Sender
  class Ffmpegservice
    class << self
      def client(sandbox: nil, account: nil)
        if account
          @ffmpegservice_account = account
          new(sandbox: account.sandbox, stream_id: account.stream_id, ffmpegservice_account: @ffmpegservice_account)
        else
          new(sandbox: sandbox)
        end
      end
    end

    # https://sandbox.cloud.ffmpegservice.com/api/v1/docs#tag/live_streams
    def initialize(sandbox: nil, stream_id: nil, ffmpegservice_account: nil)
      if ffmpegservice_account
        @ffmpegservice_account = ffmpegservice_account
        @sandbox = Rails.env.test? || ffmpegservice_account.sandbox
        @stream_id  = stream_id || ffmpegservice_account.stream_id
      else
        @sandbox    = Rails.env.test? || sandbox
        @stream_id  = stream_id
      end

      @expected_status = [200, 201]
    end

    # ---
    # live_stream:
    #     id: vvfjk49v
    #     name: ddddddd
    #     transcoder_type: transcoded
    #     billing_mode: pay_as_you_go
    #     broadcast_location: us_central_iowa
    #     recording: true
    #     closed_caption_type: none
    #     low_latency: false
    #     encoder: other_rtmp
    #     delivery_method: push
    #     delivery_protocol: hls-https
    #     target_delivery_protocol: hls-https
    #     use_stream_source: false
    #     aspect_ratio_width: 1920
    #     aspect_ratio_height: 1080
    #     delivery_protocols:
    #         - hls
    #     source_connection_information:
    #         primary_server: rtmp://3d284e-sandbox.entrypoint.cloud.ffmpegservice.com/app-5c07
    #         host_port: 1935
    #         stream_name: bdc25c80
    #         disable_authentication: true
    #         username:
    #         password:
    #         video_fallback: false
    #     player_id: ffwnwvv1
    #     player_type: original_html5
    #     player_responsive: false
    #     player_width: 640
    #     player_countdown: false
    #     player_embed_code: in_progress
    #     player_hds_playback_url: https://3d284e-sandbox.entrypoint.cloud.ffmpegservice.com/app-5c07/ngrp:65d56680_all/manifest.f4m
    #     player_hls_playback_url: https://3d284e-sandbox.entrypoint.cloud.ffmpegservice.com/app-5c07/ngrp:65d56680_all/playlist.m3u8
    #     hosted_page: false
    #     hosted_page_logo_image_url: false
    #     stream_targets: []
    #     direct_playback_urls: {}
    #     created_at: '2018-03-06T11:26:59.000Z'
    #     updated_at: '2018-03-06T11:27:00.000Z'
    #     links:
    #         - rel: self
    #     method: GET
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v
    #     - rel: update
    #     method: PATCH
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v
    #     - rel: state
    #     method: GET
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/state
    #     - rel: thumbnail_url
    #     method: GET
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/thumbnail_url
    #     - rel: start
    #     method: PUT
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/start
    #     - rel: reset
    #     method: PUT
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/reset
    #     - rel: stop
    #     method: PUT
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/stop
    #     - rel: regenerate_connection_code
    #     method: PUT
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v/regenerate_connection_code
    #     - rel: delete
    #     method: DELETE
    #     href: https://api-sandbox.cloud.ffmpegservice.com/api/v1/live_streams/vvfjk49v
    def create_live_stream(params: {})
      @method = :post
      @path = '/api/v1.11/live_streams'
      @expected_status = [200, 201, 503] if @sandbox
      @body =
        {
          live_stream: {
            name: (params[:name] || Time.now.utc.to_fs(:db)),
            aspect_ratio_height: (params[:aspect_ratio_height] || 1080),
            aspect_ratio_width: (params[:aspect_ratio_width] || 1920),
            billing_mode: 'pay_as_you_go',
            broadcast_location: 'us_central_iowa',
            encoder: (params[:encoder] || ((params[:delivery_method].to_sym == :pull) ? 'ipcamera' : 'other_rtmp')),
            transcoder_type: (params[:transcoder_type] || 'passthrough'),
            closed_caption_type: 'none',
            delivery_method: (params[:delivery_method] || 'push'),
            delivery_protocols: (params[:delivery_protocols] || %w[hls]),
            # delivery_type: 'single-bitrate',
            disable_authentication: (params[:disable_authentication] || false), #---------------
            password: (params[:password] || ((Digest::MD5.hexdigest(Time.now.to_s).to_s)[0..8]).to_s),
            username: (params[:username] || ((Digest::MD5.hexdigest(Time.now.to_s).to_s)[9..17]).to_s),
            hosted_page: false,
            low_latency: false,
            recording: true,
            source_url: ('rtsp://localhost' if params[:delivery_method].to_sym == :pull),
            use_stream_source: false,
            vod_stream: params[:vod_stream]
          }.compact
        }.to_json
      if (response = sender[:live_stream])
        @stream_id = response[:id]
        response
      else
        false
      end
    end

    def update_live_stream(live_stream: {}, stream_id: nil)
      stream_id ||= @stream_id
      @method = :patch
      @path = "/api/v1.11/live_streams/#{stream_id}"
      @body = {
        live_stream: live_stream
      }.to_json
      begin
        sender
      rescue StandardError
        false
      end
    end

    def live_streams(page: 1, per_page: 10)
      @method = :get
      @path = '/api/v1.11/live_streams'
      @query = { page: page, per_page: per_page }
      sender[:live_streams]
    end

    def live_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/live_streams/#{stream_id}/"
      @expected_status = [200, 201]
      if (response = sender[:live_stream])
        @stream_id = response[:id]
        response
      else
        false
      end
    end

    alias_method :livestream, :live_stream

    def start_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/live_streams/#{stream_id}/start"
      @expected_status = [200, 201]
      sender
    end

    def reset_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/live_streams/#{stream_id}/reset"
      sender
    end

    def stop_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/live_streams/#{stream_id}/stop"
      begin
        sender
      rescue StandardError
        false
      end
    end

    def delete_live_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :delete
      @path = "/api/v1.11/live_streams/#{stream_id}"
      @expected_status = [200, 204]
      sender
    end

    def transcoders(params = {})
      @method = :get
      @path = '/api/v1.11/transcoders'
      @expected_status = [200]
      @query = params.to_param
      sender
    end

    def start_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/transcoders/#{stream_id}/start"
      sender[:transcoder]
    end

    def stop_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/transcoders/#{stream_id}/stop"
      sender[:transcoder]
    end

    def reset_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :put
      @path = "/api/v1.11/transcoders/#{stream_id}/reset"
      sender[:transcoder]
    end

    # delivery_method: "pull",
    # name: "My PAYG Transcoder",
    # protocol: "rtmp",
    # broadcast_location: "us_central_iowa",
    # buffer_size: 4000,
    # closed_caption_type: "cea",
    # delivery_protocols: [],
    # description: "My Transcoder Description",
    # disable_authentication: false,
    # idle_timeout: 1200,
    # low_latency: false,
    # password: "82e0e971",
    # play_maximum_connections: 20,
    # recording: true,
    # remove_watermark_image: true,
    # source_url: "cp12345.live.edgefcs.net/live/redcarpet@123456",
    # stream_extension: ".sdp",
    # stream_smoother: false,
    # stream_source_id: "rxHQQpWw",
    # suppress_stream_target_start: false,
    # username: "client2",
    # video_fallback: false,
    # watermark: true,
    # watermark_height: 80,
    # watermark_image: "https://prod.s3.amazonaws.com/uploads/transcoder/watermark_image/12345/4baa13.jpg",
    # watermark_opacity: 75,
    # watermark_position: "bottom-left",
    # watermark_width: 100
    def update_transcoder(transcoder: {}, transcoder_id: nil)
      transcoder_id ||= @stream_id
      @method = :patch
      @path = "/api/v1.11/transcoders/#{transcoder_id}"
      @body = { transcoder: transcoder }.to_json
      begin
        result = sender[:transcoder]
        return false if !result.is_a?(Hash) || result.empty?

        result
      rescue StandardError => e
        Airbrake.notify(e)
        false
      end
    end

    def create_transcoder(params: {})
      @method = :post
      @path = '/api/v1.11/transcoders'
      @expected_status = [200, 201, 503] if @sandbox
      protocol = (params[:protocol] || ((params[:delivery_method] == 'pull') ? 'rtsp' : 'rtmp'))
      current_service = case protocol.to_s
                        when 'rtmp'
                          'rtmp'
                        when 'rtsp'
                          'ipcam'
                        when 'webrtc'
                          'webrtc'
                        else
                          'main'
                        end
      authentication = !params[:disable_authentication]
      @body =
        {
          transcoder: {
            billing_mode: 'pay_as_you_go',
            broadcast_location: 'us_west_california',
            delivery_method: (params[:delivery_method] || 'pull'),
            protocol: protocol,
            name: (params[:name] || FfmpegserviceAccount.new(current_service: current_service).default_custom_name),
            transcoder_type: (params[:transcoder_type] || 'passthrough'),
            closed_caption_type: 'none',
            delivery_protocols: %w[rtmp rtsp wowz hls webrtc],
            low_latency: false,
            source_url: ('rtsp://localhost' if params[:delivery_method].to_s == 'pull'),
            disable_authentication: !authentication,
            username: (params[:username] || (authentication ? SecureRandom.alphanumeric(8) : nil)),
            password: (params[:password] || (authentication ? SecureRandom.alphanumeric(8) : nil)),
            idle_timeout: params[:idle_timeout] || 1200
          }.compact
        }.to_json
      if (response = sender[:transcoder])
        @stream_id = response[:id]
        response
      else
        false
      end
    end

    def get_transcoder(stream_id = nil, params = {})
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/transcoders/#{stream_id}"
      @expected_status = params[:expected_status] || [200, 201]
      sender[:transcoder]
    end

    def state_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/live_streams/#{stream_id}/state"
      sender[:live_stream]
    end

    def state_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/transcoders/#{stream_id}/state"
      sender[:transcoder]
    end

    def stats_stream(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/live_streams/#{stream_id}/stats"
      sender[:live_stream]
    end

    def stream_active?(stream_id = nil)
      stream_id ||= @stream_id
      begin
        stats_stream(stream_id)[:connected][:value].casecmp('yes').zero?
      rescue StandardError
        false
      end
    end

    def stats_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/analytics/ingest/live_streams/#{stream_id}"
      sender[:live_stream]
    end

    def transcoder_active?(stream_id = nil)
      stream_id ||= @stream_id
      begin
        stats_transcoder(stream_id)[:connected][:value].casecmp('yes').zero?
      rescue StandardError
        false
      end
    end

    def delete_transcoder(stream_id = nil)
      stream_id ||= @stream_id
      @method = :delete
      @path = "/api/v1.11/transcoders/#{stream_id}"
      sender
    end

    def recordings
      @method = :get
      @path = '/api/v1.11/recordings'
      sender[:recordings]
    end

    def recording(recording_id)
      @method = :get
      @path = "/api/v1.11/recordings/#{recording_id}"
      @expected_status = [200, 404, 410]
      sender[:recording] || {}
    end

    def delete_recording(ffmpegservice_videо_id)
      @method = :delete
      @path = "/api/v1.11/recordings/#{ffmpegservice_videо_id}"
      @expected_status = [200, 201, 204]
      sender[:recordings]
    end

    def transcoder_schedules(stream_id = nil)
      stream_id ||= @stream_id
      @method = :get
      @path = "/api/v1.11/transcoders/#{stream_id}/schedules"
      @expected_status = [200]
      sender[:schedules]
    end

    def create_schedule_stop(stream_id, stop_at)
      @method = :post
      @path = '/api/v1.11/schedules'
      @expected_status = [201]
      @body = {
        schedule: {
          action_type: 'stop',
          name: "scheduled stop for stream #{stream_id}, #{stop_at.utc}",
          recurrence_type: 'once',
          transcoder_id: stream_id,
          stop_transcoder: stop_at.utc.to_s
        }
      }.to_json
      sender[:schedule]
    end

    def delete_schedule(schedule_id)
      @method = :delete
      @path = "/api/v1.11/schedules/#{schedule_id}"
      @expected_status = [204]
      sender
    end

    def transcoders_usage(from, to)
      @method = :get
      @path = '/api/v1.11/usage/transcoders'
      @expected_status = [200]
      @query = {
        from: from.utc.to_s,
        to: to.utc.to_s,
        per_page: 1000
      }
      sender
    end

    def create_stream_target_fastly(name)
      @method = :post
      @path = '/api/v1.11/stream_targets/fastly'
      @expected_status = [200, 201, 503] if @sandbox
      @body =
        {
          stream_target_fastly: {
            name: name
          }
        }.to_json
      if (response = sender[:stream_target_fastly])
        response
      else
        false
      end
    end

    def stream_target_fastly(stream_target_id)
      @method = :get
      @path = "/api/v1.11/stream_targets/fastly/#{stream_target_id}"
      @expected_status = [200, 201, 503] if @sandbox
      if (response = sender[:stream_target_fastly])
        response
      else
        false
      end
    end

    def create_output(transcoder_id: nil, params: {})
      transcoder_id ||= @stream_id
      @method = :post
      @path = "/api/v1.11/transcoders/#{transcoder_id}/outputs"
      @expected_status = [200, 201, 503] if @sandbox
      @body =
        {
          output: {
            video_codec: (params[:video_codec] || 'passthrough'),
            audio_codec: (params[:audio_codec] || 'passthrough')
          }
        }.to_json
      if (response = sender[:output])
        response
      else
        false
      end
    end

    def delete_transcoder_output(output_id, transcoder_id = nil)
      transcoder_id ||= @stream_id
      @method = :delete
      @path = "/api/v1.11/transcoders/#{transcoder_id}/outputs/#{output_id}"
      @expected_status = [204]
      sender
    end

    def create_output_stream_target(output_id:, stream_target_id:, transcoder_id: nil)
      transcoder_id ||= @stream_id
      @method = :post
      @path = "/api/v1.11/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets"
      @expected_status = [200, 201, 503] if @sandbox
      @body = {
        output_stream_target: {
          stream_target_id: stream_target_id
        }
      }.to_json
      if (response = sender[:output_stream_target])
        response
      else
        false
      end
    end

    def request(path, params = {})
      @path = path

      params = params.with_indifferent_access
      @method = params[:method] || :get
      @query = params[:query] || {}
      @body = (params[:body] || {}).to_json
      @expected_status = params[:expected_status] || [200]
      sender
    end

    private

    def sender
      if @sandbox
        return Sender::FfmpegserviceSandbox.new(path: @path, body: @body, ffmpegservice_account: @ffmpegservice_account,
                                        method: @method).response
      end
      ffmpegservice_jwt = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :jwt_token)
      debug = !Rails.env.production? || Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :debug)
      @client = Excon.new('https://api.video.ffmpegservice.com/',
                          headers: {
                            'Authorization' => "Bearer #{ffmpegservice_jwt}",
                            'Content-Type' => 'application/json',
                            'Accept' => 'application/json'
                          },
                          debug_request: debug,
                          debug_response: debug)

      logger = Logger.new "#{Rails.root}/log/debug_ffmpegservice_sender.#{Rails.env}.#{`hostname`.to_s.strip}.log"
      logger.info("#{@method} #{@path}, @body: #{@body}, @query: #{@query.to_json}")

      begin
        response = @client.request(
          method: @method, path: @path, body: @body, query: @query, expects: @expected_status,
          idempotent: true, retry_limit: 2, retry_interval: 0.1,
          read_timeout: 5, write_timeout: 5, connect_timeout: 5
        )
        @body = nil
        @query = nil

        if response&.body.blank?
          {}
        else
          JSON.parse(response.body).with_indifferent_access
        end
      rescue StandardError => e
        logger.info("Error response #{@method} #{@path}, #{e.message}")
        Airbrake.notify(e,
                        parameters: {
                          path: @path,
                          query: @query,
                          request_body: @body
                        })
        {}
      end
    end
  end
end
