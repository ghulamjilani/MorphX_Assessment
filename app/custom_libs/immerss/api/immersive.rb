# frozen_string_literal: true

module Immerss
  module Api
    class Immersive
      def self.client
        new
      end

      def initialize
        @client = Excon.new(ENV['API_URL'],
                            headers: {
                              'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
                                ENV['PORTAL_API_LOGIN'], ENV['PORTAL_API_PASSWORD']
                              ),
                              'Content-Type' => 'application/json',
                              'Accept' => 'application/json'
                            },
                            debug_request: !Rails.env.production?,
                            debug_response: !Rails.env.production?,
                            ssl_verify_peer: false)
      end

      def participant_auth(session_id, user_id, role = 'participant', source_id = nil)
        @method = :post
        @path = "portal/sessions/#{session_id}/auth/#{user_id}"
        @expected_status = [200, 404]
        @query = { role: role, source_id: source_id }
        @caller = :participant_auth
        sender
      end

      # REMOVEME AFTER FIX LOBBIES PAGE
      # def after_join(session_id, user_id, role = 'participant', source_id = nil)
      #   @method = :post
      #   @path = "portal/sessions/#{session_id}/after_join/#{user_id}"
      #   @expected_status = [200]
      #   @query = {role: role, source_id: source_id}
      #   @caller = :after_join
      #   sender
      # end

      def start_session(room_id)
        @method = :post
        @path = "portal/sessions/#{room_id}/start"
        @expected_status = [200]
        @caller = :start_session
        sender
      end

      def be_right_back(room_id, on = true)
        @method = :post
        @path = "portal/sessions/#{room_id}/be_right_back"
        @expected_status = [200]
        @caller = :be_right_back
        @query = { on: on }
        sender
      end

      def scheduled_stop_session(room_id)
        @method = :post
        @path = "scheduling_service/sessions/#{room_id}/stop_session"
        @expected_status = [200]
        @caller = :scheduled_stop_session
        sender
      end

      def scheduled_auto_start_session(room_id)
        @method = :post
        @path = "scheduling_service/sessions/#{room_id}/auto_start_personal_session"
        @expected_status = [200]
        @caller = :auto_start_personal_session
        sender
      end

      def start_or_resume_record(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/start_or_resume_record"
        @expected_status = [200]
        @caller = :start_or_resume_record
        sender
      end

      def start_record(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/start_record"
        @expected_status = [200]
        @caller = :start_record
        sender
      end

      def stop_record(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/stop_record"
        @expected_status = [200]
        @caller = :stop_record
        sender
      end

      def pause_record(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/pause_record"
        @expected_status = [200]
        @caller = :pause_record
        sender
      end

      def resume_record(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/resume_record"
        @expected_status = [200]
        @caller = :resume_record
        sender
      end

      def answer(room_id, question_id, user_id)
        @method = :post
        @path = "portal/#{room_id}/questions/#{question_id}/answer"
        @query = { user_id: user_id }
        @expected_status = [200]
        @caller = :answer
        sender
      end

      def ask(room_id, user_id)
        @method = :post
        @path = "portal/#{room_id}/questions"
        @query = { user_id: user_id }
        @expected_status = [200]
        @caller = :ask
        sender
      end

      def silence_all(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/silence_all"
        @expected_status = [200]
        @caller = :silence_all
        sender
      end

      def allow_control(session_id, co_presenter_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/allow_control"
        @expected_status = [200]
        @query = { co_presenter_id: co_presenter_id }
        @caller = :allow_control
        sender
      end

      def disable_control(session_id, co_presenter_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/disable_control"
        @expected_status = [200]
        @query = { co_presenter_id: co_presenter_id }
        @caller = :disable_control
        sender
      end

      def mute(session_id, member_id, source_id = nil)
        @method = :post
        @path = "portal/sessions/#{session_id}/mute"
        @expected_status = [200]
        @query = { member_id: member_id, source_id: source_id }
        @caller = :mute
        sender
      end

      def unmute(session_id, member_id, source_id = nil)
        @method = :post
        @path = "portal/sessions/#{session_id}/unmute"
        @expected_status = [200]
        @query = { member_id: member_id, source_id: source_id }
        @caller = :unmute
        sender
      end

      def mute_all(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/mute_all"
        @expected_status = [200]
        @caller = :mute_all
        sender
      end

      def unmute_all(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/unmute_all"
        @expected_status = [200]
        @caller = :unmute_all
        sender
      end

      def start_video(session_id, member_id, source_id = nil)
        @method = :post
        @path = "portal/sessions/#{session_id}/start_video"
        @expected_status = [200]
        @query = { member_id: member_id, source_id: source_id }
        @caller = :start_video
        sender
      end

      def stop_video(session_id, member_id, source_id = nil)
        @method = :post
        @path = "portal/sessions/#{session_id}/stop_video"
        @expected_status = [200]
        @query = { member_id: member_id, source_id: source_id }
        @caller = :stop_video
        sender
      end

      def start_all_videos(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/start_all_videos"
        @expected_status = [200]
        @caller = :start_all_videos
        sender
      end

      def start_fb_stream(session_id, url)
        @method = :post
        @path = "portal/sessions/#{session_id}/start_fb_stream"
        @query = { url: url }
        @expected_status = [200]
        @caller = :start_fb_stream
        sender
      end

      def stream_pid(room_id, provider, kill_process)
        @method = :post
        @path = "portal/sessions/#{room_id}/stream_pid"
        @query = { provider: provider, kill_process: kill_process }
        @expected_status = [200, 404, 502]
        @caller = :start_fb_stream
        sender
      end

      def start_youtube_stream(room_id)
        @method = :post
        @path = "portal/sessions/#{room_id}/start_youtube_stream"
        @expected_status = [200]
        @caller = :start_youtube_stream
        sender
      end

      def start_immerss_stream(room_id)
        @method = :post
        @path = "portal/sessions/#{room_id}/start_immerss_stream"
        @expected_status = [200]
        @caller = :start_immerss_stream
        sender
      end

      def stop_all_videos(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/stop_all_videos"
        @expected_status = [200]
        @caller = :stop_all_videos
        sender
      end

      def enable_backstage(session_id, member_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/enable_backstage"
        @expected_status = [200]
        @query = { member_id: member_id }
        @caller = :enable_backstage
        sender
      end

      def disable_backstage(session_id, member_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/disable_backstage"
        @expected_status = [200]
        @query = { member_id: member_id }
        @caller = :disable_backstage
        sender
      end

      def enable_all_backstage(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/enable_all_backstage"
        @expected_status = [200]
        @caller = :enable_all_backstage
        sender
      end

      def disable_all_backstage(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/disable_all_backstage"
        @expected_status = [200]
        @caller = :disable_all_backstage
        sender
      end

      def stop_lecture_mode(session_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/stop_lecture_mode"
        @expected_status = [200]
        @caller = :stop_lecture_mode
        sender
      end

      def ban_kick(session_id, banner_id, banned_id, reason_id)
        @method = :post
        @path = "portal/sessions/#{session_id}/ban_kick"
        @expected_status = [200]
        @query = { banner_id: banner_id, banned_id: banned_id, reason_id: reason_id }
        @caller = :ban_kick
        sender
      end

      private

      def sender
        query = @query.is_a?(Hash) ? @query : {}
        query[:time_travel] = Time.now unless Rails.env.production?

        exists_path = @client.data[:path]
        path = if exists_path.present? && exists_path != '/'
                 exists_path + @path
               else
                 @path
               end
        @client.request(expects: @expected_status, method: @method, path: path, query: query)
      rescue StandardError => e
        Airbrake.notify(RuntimeError.new("Server #{ENV['API_URL']} return exception for method Immersive.#{@caller}"),
                        parameters: {
                          message: e.message,
                          expects: @expected_status,
                          method: @method,
                          path: @path,
                          query: @query
                        })
        false
      end
    end
  end
end
