# frozen_string_literal: true

module Sender
  class ZoomLib
    attr_reader :new_refresh_token, :access_token

    def initialize(identity:)
      @identity = identity
      @access_token = @identity.token
      @authorize = "Bearer #{@access_token}" # for token query use basic auth, for all other queries use access_token
      @uid = @identity.uid
      refresh_token if token_expired?
    end

    # https://marketplace.zoom.us/docs/api-reference/zoom-api/users/user
    def user
      @method = :get
      @path = "/v2/users/#{@uid}"
      @expected_status = [200]
      sender
    end

    def plan_info(account_id)
      @method = :get
      @path = "/v2/accounts/#{account_id}/plans"
      @expected_status = [200]
      sender
    end

    def plan_usage
      @method = :get
      @path = '/v2/accounts/me/plans/usage'
      @expected_status = [200]
      sender
    end

    def recordings
      @method = :get
      @path = "/v2/users/#{@uid}/recordings"
      @expected_status = [200]
      sender
    end

    def meeting(meeting_id)
      @method = :get
      @path = "/v2/meetings/#{meeting_id}"
      @expected_status = [200]
      sender
    end

    def delete_recordings(meeting_id)
      @method = :delete
      @path = "/v2/meetings/#{meeting_id}/recordings"
      @expected_status = [200]
      sender
    end

    def meeting_recordings(meeting_id)
      @method = :get
      @path = "/v2/meetings/#{meeting_id}/recordings"
      @expected_status = [200]
      sender
    end

    # https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingcreate
    # {\"uuid\":\"7TBoqvrkRf+2TJHObDtR9Q==\",\"id\":95563867285,\"host_id\":\"dOa20cyiTNK2W8X3pQIbGQ\",\"host_email\":\"apps@morphx.io\",\"topic\":\"Super puper session\",\"type\":1,\"status\":\"waiting\",\"timezone\":\"America/Los_Angeles\",\"agenda\":\"Pss session is coming\",\"created_at\":\"2020-12-24T13:45:39Z\",\"start_url\":\"https://zoom.us/s/95563867285?zak=eyJ6bV9za20iOiJ6bV9vMm0iLCJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJjbGllbnQiLCJ1aWQiOiJkT2EyMGN5aVROSzJXOFgzcFFJYkdRIiwiaXNzIjoid2ViIiwic3R5IjoxLCJ3Y2QiOiJhdzEiLCJjbHQiOjAsInN0ayI6InF2Sm5zbkJQb2FvWlJfOHIzcmszTzBoVjg0dDhEcmQyMXZzVXNLdzIwWGcuQUcuRDRsa2xtanFMOXVGUFJlZnNNVUpNUVg2cXlJdGppa1BKdWxKM010eVpDOGRmeHVDSkotTFB2dEpQSVdzeDlHUnladEkxZE0tZkQzQWFxNC54cERjSWItUFZRVXZMMC10TUFXOHVRLkFGaGo1TFh6eUV0Y3ljSzIiLCJleHAiOjE2MDg4MjQ3MzksImlhdCI6MTYwODgxNzUzOSwiYWlkIjoiRTN2a2szdVlRLUNvSHVLZHBZSlRNZyIsImNpZCI6IiJ9._OTpwgeKGgVa9yW7kO5fC1JLB1EvV6q_y6rd_UXb6dc\",\"join_url\":\"https://zoom.us/j/95563867285?pwd=djlyaWlsbXA1UnFMOE91M3NVSElzQT09\",\"password\":\"b406106d2c\",\"h323_password\":\"5382133825\",\"pstn_password\":\"5382133825\",\"encrypted_password\":\"djlyaWlsbXA1UnFMOE91M3NVSElzQT09\",\"settings\":{\"host_video\":false,\"participant_video\":false,\"cn_meeting\":false,\"in_meeting\":false,\"join_before_host\":false,\"jbh_time\":0,\"mute_upon_entry\":false,\"watermark\":false,\"use_pmi\":false,\"approval_type\":2,\"audio\":\"voip\",\"auto_recording\":\"none\",\"enforce_login\":false,\"enforce_login_domains\":\"\",\"alternative_hosts\":\"\",\"close_registration\":false,\"show_share_button\":true,\"allow_multiple_devices\":true,\"registrants_confirmation_email\":true,\"waiting_room\":false,\"request_permission_to_unmute_participants\":false,\"contact_name\":\"Apps Morphx\",\"contact_email\":\"apps@morphx.io\",\"registrants_email_notification\":false,\"meeting_authentication\":false,\"encryption_type\":\"enhanced_encryption\",\"approved_or_denied_countries_or_regions\":{\"enable\":false}}}"
    def create_meeting(params)
      @method = :post
      @path = "/v2/users/#{@uid}/meetings"
      @expected_status = [200, 201]
      @query = {}
      @body = {
        topic: params[:topic],
        type: params[:type],
        start_time: params[:start_time],
        agenda: params[:agenda],
        duration: params[:duration],
        timezone: params[:timezone],
        # schedule_for: nil,
        # password: SecureRandom.hex[0..9],
        # recurrence: {
        #     type: nil,
        #     repeat_interval: nil,
        #     weekly_days: nil,
        #     monthly_day: nil,
        #     monthly_week: nil,
        #     monthly_week_day: nil,
        #     end_times: nil,
        #     end_date_time: nil
        # },
        settings: {
          jbh_time: params[:settings][:jbh_time],
          approval_type: 2, # No registration required.
          auto_recording: params[:settings][:auto_recording],
          host_video: false,
          participant_video: false,
          join_before_host: false,
          waiting_room: true, # Enable waiting room. Note that if the value of this field is set to true, it will override and disable the join_before_host setting.
          mute_upon_entry: false,
          watermark: false,
          use_pmi: false,
          registration_type: 2,
          audio: true,
          enforce_login: false,
          enforce_login_domains: '',
          alternative_hosts: '',
          global_dial_in_countries: nil,
          registrants_email_notification: true
        }
      }.to_json
      sender
    end

    # https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingstatus
    def end_meeting(meeting_id)
      @method = :put
      @path = "/v2/meetings/#{meeting_id}/status"
      @expected_status = [200, 204]
      @query = {}
      @body = {
        action: 'end'
      }.to_json
      sender
    end

    def revoke_token
      @authorize = ActionController::HttpAuthentication::Basic.encode_credentials(
        Rails.application.credentials.backend[:initialize][:zoom][:client_id],
        Rails.application.credentials.backend[:initialize][:zoom][:client_secret]
      )
      resp = revoke(token: @identity.token)
      resp[:status]
    end

    private

    # {\"access_token\":\"eyJhbGciOiJIUzUxMiIsInYiOiIyLjAiLCJraWQiOiI2ZGI2ZjUyNi01ZmViLTRiZWUtYWFiNi0zMzllZjJhYTUzYTUifQ.eyJ2ZXIiOjcsImF1aWQiOiI0MDAzYzI5YzQwNjVmNThlMjk5MmMzNzQyYWZiMjdmYiIsImNvZGUiOiJOVnNiNGdQRTdDX2RPYTIwY3lpVE5LMlc4WDNwUUliR1EiLCJpc3MiOiJ6bTpjaWQ6bzBfSnlQUnhUSU83REhaTk52U2NRIiwiZ25vIjowLCJ0eXBlIjowLCJ0aWQiOjEsImF1ZCI6Imh0dHBzOi8vb2F1dGguem9vbS51cyIsInVpZCI6ImRPYTIwY3lpVE5LMlc4WDNwUUliR1EiLCJuYmYiOjE2MDg4MTEwNzUsImV4cCI6MTYwODgxNDY3NSwiaWF0IjoxNjA4ODExMDc1LCJhaWQiOiJFM3ZrazN1WVEtQ29IdUtkcFlKVE1nIiwianRpIjoiYjIyZjM3YTUtNDQxZS00NjRjLTgyZmItOTAxMWQ5Y2NkZWQ3In0.AvXhEejsjkv3mc7C1QbD7IfC0362Ka4VfNgdjwDY6nN7bPGnkg33zXlFhXnQ7FvaTdFwvgqA7PgL2LBCcKSEkw\",
    # \"token_type\":\"bearer\",
    # \"refresh_token\":\"eyJhbGciOiJIUzUxMiIsInYiOiIyLjAiLCJraWQiOiI1M2JiMDQwMy1kYTBmLTRjMTItYWQyNi1mMWIxZTQ0MmRjYmMifQ.eyJ2ZXIiOjcsImF1aWQiOiI0MDAzYzI5YzQwNjVmNThlMjk5MmMzNzQyYWZiMjdmYiIsImNvZGUiOiJOVnNiNGdQRTdDX2RPYTIwY3lpVE5LMlc4WDNwUUliR1EiLCJpc3MiOiJ6bTpjaWQ6bzBfSnlQUnhUSU83REhaTk52U2NRIiwiZ25vIjowLCJ0eXBlIjoxLCJ0aWQiOjEsImF1ZCI6Imh0dHBzOi8vb2F1dGguem9vbS51cyIsInVpZCI6ImRPYTIwY3lpVE5LMlc4WDNwUUliR1EiLCJuYmYiOjE2MDg4MTEwNzUsImV4cCI6MjA4MTg1MTA3NSwiaWF0IjoxNjA4ODExMDc1LCJhaWQiOiJFM3ZrazN1WVEtQ29IdUtkcFlKVE1nIiwianRpIjoiODAwN2QwOGYtNzE1Yy00ZmE5LWI0YWEtNWZmZjA0ZjY5NGUwIn0.mJdevZNfasK0mK-GtphKFNQPTC9qkwd0leHp72dgXTya9LoR3BIyZ00jfv5gI_1B3FTMBaJsxvQhIYThuypR9A\",
    # \"expires_in\":3599,\"scope\":\"meeting:read meeting:write recording:read recording:write user:read user:write user_profile\"}
    def token(refresh_token:)
      @method = :post
      @path = '/oauth/token'
      @expected_status = [200]
      @query = {
        grant_type: :refresh_token,
        refresh_token: refresh_token
      }
      sender
    end

    def revoke(token:)
      @method = :post
      @path = '/oauth/revoke'
      @expected_status = [200]
      @query = {
        token: token
      }
      sender
    end

    def sender
      client = Excon.new('https://zoom.us',
                         headers: {
                           'Authorization' => @authorize,
                           'Content-Type' => 'application/json',
                           'Accept' => 'application/json'
                         },
                         debug_request: !Rails.env.production?,
                         debug_response: !Rails.env.production?,
                         ssl_verify_peer: false)
      response = client.request(
        idempotent: true, retry_limit: 2, retry_interval: 5, expects: @expected_status,
        method: @method, path: @path, body: @body, query: @query
      )
      @body = @query = nil
      begin
        if response.body.blank?
          {}
        else
          JSON.parse(response.body).with_indifferent_access
        end
      rescue StandardError => e
        Airbrake.notify(e.message, parameters: { body: response.body })
        {}
      end
    end

    def refresh_token
      # @authorize = ActionController::HttpAuthentication::Basic.encode_credentials('o0_JyPRxTIO7DHZNNvScQ', 'dp1NIeUdXI2rSMPCqzaR0Rx31RLZqD3Z')
      @authorize = ActionController::HttpAuthentication::Basic.encode_credentials(
        Rails.application.credentials.backend[:initialize][:zoom][:client_id],
        Rails.application.credentials.backend[:initialize][:zoom][:client_secret]
      )
      resp = token(refresh_token: @identity.secret)
      puts resp
      @access_token = resp[:access_token]
      @new_refresh_token = resp[:refresh_token]
      expires_at = resp['expires_in'].to_i.seconds.from_now
      @authorize = "Bearer #{@access_token}" # for token query use basic auth, for all other queries use access_token
      @uid = JWT.decode(@access_token, nil, false)[0]['uid']
      @identity.update(token: @access_token, secret: @new_refresh_token, expires_at: expires_at)
    end

    def token_expired?
      @identity.expires_at <= Time.now
    end
  end
end
