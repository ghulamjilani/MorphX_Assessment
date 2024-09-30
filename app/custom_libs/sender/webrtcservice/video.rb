# frozen_string_literal: true

module Sender
  module Webrtcservice
    class Video
      include Rails.application.routes.url_helpers

      class << self
        def client(room = nil)
          new(room)
        end
      end

      def initialize(room = nil)
        @room = room
        @session = @room&.session
        @unique_name = @session.unique_webrtcservice_name if @session.present?
        webrtcservice_config = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :video)
        @service_prefix = webrtcservice_config[:service_prefix]
        raise 'backend:initialize:webrtcservice:video:service_prefix in application credentials is required' unless @service_prefix

        @api_key = webrtcservice_config[:api_key]
        raise 'backend:initialize:webrtcservice:video:api_key in application credentials is required' unless @api_key

        @api_secret = webrtcservice_config[:api_secret]
        raise 'backend:initialize:webrtcservice:video:api_secret in application credentials is required' unless @api_secret

        @expected_status = [200, 201, 202, 400, 404]
        @base_url = 'https://video.webrtcservice.com'
      end

      def rooms(params = {})
        path = '/v1/Rooms'
        full_list(path, :rooms, params)
      end

      def rooms_completed(params = {})
        path = '/v1/Rooms'
        params = { Status: 'completed' }.merge(params)
        full_list(path, :rooms, params)
      end

      # room_data example:
      # {
      #   Type: 'group', # go, peer-to-peer, group-small, or group
      #   UniqueName: 'TestRoom', # Optional
      #   StatusCallback: 'https://dev.morphx.io/webhook/webrtcservice/video/{room_id}',
      #   StatusCallbackMethod: 'GET', # Can be POST or GET
      #   MaxParticipants: 'GET', # Can be POST or GET
      #   RecordParticipantsOnConnect: 'True'
      #   VideoCodecs[]: 'VP8' # Can be: VP8 and H264
      #   MediaRegion: 'us1', # https://www.webrtcservice.com/docs/video/ip-addresses#group-rooms-media-servers
      # }
      def create_room(unique_name, room_data = {})
        @expected_status = [200, 201]
        @method = :post
        @path = '/v1/Rooms'
        token = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :webhook, :token)
        room_data = {
          UniqueName: unique_name,
          EmptyRoomTimeout: 60,
          UnusedRoomTimeout: 60,
          RecordParticipantsOnConnect: (@session&.do_record? ? 'True' : 'False'),
          MaxParticipants: (@session&.max_number_of_immersive_participants.to_i + 1),
          StatusCallback: "https://#{Rails.application.credentials.global[:host]}#{webhook_v1_webrtcservice_index_path(token: token)}",
          StatusCallbackMethod: 'POST'
        }.merge(room_data)
        @body = URI.encode_www_form(room_data)
        sender
      end

      # https://www.webrtcservice.com/docs/video/api/rooms-resource
      # {
      #   "account_sid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      #   "date_created": "2015-07-30T20:00:00Z",
      #   "date_updated": "2015-07-30T20:00:00Z",
      #   "status": "completed",
      #   "type": "peer-to-peer",
      #   "sid": "RMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      #   "enable_turn": true,
      #   "unique_name": "unique_name",
      #   "max_participants": 10,
      #   "max_concurrent_published_tracks": 10,
      #   "status_callback_method": "POST",
      #   "status_callback": "",
      #   "record_participants_on_connect": false,
      #   "video_codecs": [
      #     "VP8"
      #   ],
      #   "media_region": "us1",
      #   "end_time": "2015-07-30T20:00:00Z",
      #   "duration": 10, #!!!!! DURATION IN SECONDS
      #   "url": "https://video.webrtcservice.com/v1/Rooms/RMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      #   "links": {
      #     "participants": "https://video.webrtcservice.com/v1/Rooms/RMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Participants",
      #     "recordings": "https://video.webrtcservice.com/v1/Rooms/RMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings",
      #     "recording_rules": "https://video.webrtcservice.com/v1/Rooms/RMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/RecordingRules"
      #   }
      # }
      # Retrieve an in-progress room by unique_name or in-progress or completed room by sid
      def room(room_sid_or_name = nil, params = {})
        room_sid_or_name ||= @unique_name
        @expected_status = params[:expected_status] || [200]
        @query = params
        @method = :get
        @path = "/v1/Rooms/#{room_sid_or_name}"
        sender
      end

      def update_room(room_sid, room_data)
        @expected_status = [200, 201, 202]
        @method = :post
        @path = "/v1/Rooms/#{room_sid}"
        @body = URI.encode_www_form(room_data)
        sender
      end

      def complete_room(room_sid_or_name = nil, params = {})
        room_sid_or_name ||= @unique_name
        @expected_status = params[:expected_status] || [200, 202]
        @method = :post
        @path = "/v1/Rooms/#{room_sid_or_name}"
        @body = URI.encode_www_form({ Status: 'completed' })
        sender
      end

      # Status # processing, completed, or deleted
      # DateCreatedAfter # ISO 8601 date-time with time zone, given as YYYY-MM-DDThh:mm:ss+|-hh:mm or YYYY-MM-DDThh:mm:ssZ
      # DateCreatedBefore
      # MediaType # audio or video
      # PageSize # 100 is max
      # Page
      def recordings(params = {})
        path = '/v1/Recordings'
        full_list(path, :recordings, params)
      end

      def recordings_completed(params = {})
        path = '/v1/Recordings'
        params = {
          Status: 'completed'
        }.merge(params)
        full_list(path, :recordings, params)
      end

      # Status # processing, completed, or deleted
      # DateCreatedAfter # ISO 8601 date-time with time zone, given as YYYY-MM-DDThh:mm:ss+|-hh:mm or YYYY-MM-DDThh:mm:ssZ
      # DateCreatedBefore
      # MediaType # audio or video
      # PageSize # 100 is max
      def room_recordings(room_sid, params = {})
        path = "/v1/Rooms/#{room_sid}/Recordings"
        full_list(path, :recordings, params)
      end

      def delete_recording(recording_sid)
        @method = :delete
        @expected_status = [204, 404]
        @path = "/v1/Recordings/#{recording_sid}"
        sender
      end

      # Status # connected or disconnected
      def room_participants(room_name_or_sid, params = {})
        path = "/v1/Rooms/#{room_name_or_sid}/Participants"
        full_list(path, :participants, params)
      end

      # Status # connected or disconnected
      def disconnect_room_participant(room_name_or_sid, identity, params = {})
        @expected_status = params[:expected_status] || [200, 202]
        @method = :post
        @path = "/v1/Rooms/#{room_name_or_sid}/Participants/#{identity}"
        @body = URI.encode_www_form({ Status: 'disconnected' })
        sender
      end

      def composition(composition_sid)
        @expected_status = [200]
        @method = :get
        @path = "/v1/Compositions/#{composition_sid}"
        sender
      end

      def compositions(params = {})
        path = '/v1/Compositions'
        full_list(path, :compositions, params)
      end

      def room_compositions(room_sid, params = {})
        path = '/v1/Compositions'
        params = {
          RoomSid: room_sid
        }.merge(params)
        full_list(path, :compositions, params)
      end

      def compositions_completed(params = {})
        path = '/v1/Compositions'
        params = {
          Status: 'completed'
        }.merge(params)
        full_list(path, :compositions, params)
      end

      def create_composition(room_sid, params)
        @expected_status = [200, 201]
        @method = :post
        @path = '/v1/Compositions'
        params = {
          RoomSid: room_sid,
          Format: 'mp4',
          AudioSources: '*',
          Resolution: '1280x720'
        }.merge(params)
        @body = URI.encode_www_form(params)
        sender
      end

      def delete_composition(composition_sid)
        @method = :delete
        @expected_status = [204]
        @path = "/v1/Compositions/#{composition_sid}"
        sender
      end

      def composition_media_url(composition_sid, params = {})
        @method = :get
        @path = "/v1/Compositions/#{composition_sid}/Media"
        @query = {
          Ttl: 3600
        }.merge(params)
        @expected_status = [200, 302]
        sender[:redirect_to]
      end

      def get_uri(path, params = {})
        @method = :get
        @path = path
        @query = params
        @expected_status = params[:expected_status] || [200]
        sender
      end

      def full_list(first_page_path, entity, params = {})
        params = {
          PageSize: 100
        }.merge(params)
        response = get_uri(first_page_path, params)
        list = []
        loop do
          new_items = response.dig(entity.to_s.pluralize.to_sym)
          next_page_url = response.dig(:meta, :next_page_url)
          list += new_items if new_items.is_a?(Array)
          break if next_page_url.nil?

          path = next_page_url.sub(@base_url, '')
          response = get_uri(path)
        end
        list
      end

      private

      def sender
        @client = Excon.new(@base_url,
                            headers: {
                              'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
                                @api_key, @api_secret
                              ),
                              'Content-Type' => 'application/x-www-form-urlencoded',
                              'Accept' => 'application/json'
                            },
                            debug_request: !Rails.env.production?,
                            debug_response: !Rails.env.production?)
        begin
          response = @client.request(
            idempotent: true, retry_limit: 1, retry_interval: (1..10).to_a.sample, expects: @expected_status,
            method: @method, path: @path, body: @body, query: @query
          )
          if response&.body.blank? || response&.status.eql?(404)
            {}
          else
            JSON.parse(response.body).with_indifferent_access
          end
        rescue StandardError => e
          Rails.logger.debug e unless Rails.env.production?
          Airbrake.notify(e, parameters: {
                            room: @room&.id,
                            path: @path,
                            method: @method,
                            query: @query,
                            body: @body,
                            response: response,
                            response_body: response&.body
                          })
          {}
        end
      end
    end
  end
end
