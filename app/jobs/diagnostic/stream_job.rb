# frozen_string_literal: true

class Diagnostic::StreamJob < ApplicationJob
  sidekiq_options queue: :critical

  def perform(*_args)
    Room.current_rooms.joins(session: :ffmpegservice_account).where(ffmpegservice_accounts: { sandbox: false }).preload(:abstract_session).limit(10).each do |room|
      wa = room.ffmpegservice_account

      session = room.abstract_session

      message = case room.status
                when 'awaiting'
                  when_awaiting(room, session, wa)
                when 'active'
                  when_active(room, session, wa)
                when 'closed'
                  when_closed(room, session, wa)
                else
                  'unknown status'
                end
      unless message == 'OK'
        user = room.presenter_user
        params = {
          time_now: Time.now.utc,
          room_id: room.id,
          room_status: room.status,
          room_start_at: room.actual_start_at,
          room_end_at: room.actual_end_at,
          session_id: session.id,
          session_start_at: session.start_at,
          session_pre_time: session.pre_time,
          session_autostart: session.autostart,
          presenter_user_id: room.presenter_user_id,
          presenter_user_name: "#{user.email};#{user.first_name};#{user.last_name}",
          wa_stream_id: wa.stream_id,
          wa_stream_up: wa.stream_up?,
          message: message
        }

        ffmpegservice_project_id = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account,
                                                                     :project_id) || '{project_id}'
        message = "Stream Error #{params[:presenter_user_name][0..100]} \n \n
            Environment: #{Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :prefix)} \n \n
            #{params[:message]}. \n
            User: #{params[:presenter_user_name]} \n
            \n
            Links: \n
            Ffmpegservice Status page: #{ENV['HOST']}/service_admin_panel/ffmpegservice_status?stream_id=#{params[:wa_stream_id]} \n
            Session: #{ENV['HOST']}/service_admin_panel/sessions/#{params[:session_id]} \n
            Room: #{ENV['HOST']}/service_admin_panel/rooms/#{params[:room_id]} \n
            User: #{ENV['HOST']}/service_admin_panel/users/#{params[:presenter_user_id]} \n
            FfmpegserviceAccount: #{ENV['HOST']}/service_admin_panel/ffmpegservice_accounts/#{wa.id} \n
            FfmpegserviceCloud: https://cloud.ffmpegservice.com/en/#{ffmpegservice_project_id}/manage/live_streams/#{params[:wa_stream_id]} \n
            \n
            Debug info \n
            time_now          #{params[:time_now]} \n
            room_status       #{params[:room_status]} \n
            room_start_at     #{params[:room_start_at]} \n
            room_end_at       #{params[:room_end_at]} \n
            session_start_at  #{params[:session_start_at]} \n
            session_pre_time  #{params[:session_pre_time]} \n
            session_autostart #{params[:session_autostart]} \n
            wa_stream_up      #{params[:wa_stream_up]} \n
            "
        Sender::Slack.notify(message, Sender::Slack::ISSUE_REPORT_CHANNEL_WEBHOOK_URL)
      end
    end
  end

  def when_awaiting(room, session, wa)
    if Time.now.utc.between?(session.start_at, room.actual_end_at) # session live time
      return 'Room has status awaiting but should have active'
    end

    if Time.now.utc.between?((room.actual_start_at + 1.minute), session.start_at) # prep time
      if wa.stream_up?
        return akamai_hls_check(wa)
      else
        wa_client = Sender::Ffmpegservice.client(account: wa)
        case state = wa_client.state_stream[:state]
        when 'starting', 'resetting'
          return 'OK'
        when 'stopping'
          return 'FfmpegserviceAccount has status stopping, please go https://cloud.ffmpegservice.com and start it'
        when 'started'
          if wa_client.stream_active?
            return 'looks like server error check StreamJob::FfmpegserviceStatus'
          elsif session.autostart
            return 'ask presenter connect the device'
          end
        when 'stopped'
          return 'FfmpegserviceAccount has status stopped, please go https://cloud.ffmpegservice.com and start it'
        else
          return "Wrong status#{state}"
        end

      end
    end

    'OK'
  end

  def when_active(room, session, wa)
    if Time.now.utc.between?((room.actual_start_at + 1.minute), session.start_at) # prep time
      return 'Room has status active in prep time'
    end

    if Time.now.utc.between?(session.start_at, room.actual_end_at) # session live time
      if wa.stream_up?
        return akamai_hls_check(wa)
      else
        wa_client = Sender::Ffmpegservice.client(account: wa)
        case state = wa_client.state_stream[:state]
        when 'starting'
          return 'OK'
        when 'stopping'
          return 'FfmpegserviceAccount has status stopping, please go https://cloud.ffmpegservice.com and start it'
        when 'started'
          if wa_client.stream_active?
            return 'looks like server error check StreamJob::FfmpegserviceStatus'
          else
            return 'ask presenter connect the device or stop the session'
          end
        when 'stopped'
          return 'FfmpegserviceAccount has status stopped, please go https://cloud.ffmpegservice.com and start it'
        when 'resetting'
          return 'FfmpegserviceAccount has status resetting, please go https://cloud.ffmpegservice.com and check it'
        else
          return "Wrong status#{state}"
        end

      end

    end

    'OK'
  end

  def when_closed(_room, _session, _wa)
    'OK'
  end

  def akamai_hls_check(wa)
    @url = wa.stream_m3u8_url
    playlist_resp = Excon.get(@url)
    unless playlist_resp.status.to_s == '200'
      raise 'ERRORURL'
    end

    chunk_playlist_path = playlist_resp.body.split("\n").last
    @chunk_playlist_url = URI.join(@url, chunk_playlist_path).to_s

    chunk_list_resp = Excon.get(@chunk_playlist_url)
    unless chunk_list_resp.status.to_s == '200'
      raise 'ERRORPLAYLIST'
    end

    chuck_path = chunk_list_resp.body.split("\n").last
    @chuck_url = URI.join(@chunk_playlist_url, chuck_path).to_s
    unless Excon.get(@chuck_url).status.to_s == '200'
      raise 'ERRORCHUNC'
    end

    @url = @chunk_playlist_url = @chuck_url = nil
    'OK'
  rescue StandardError => e
    Sender::Ffmpegservice.client(account: wa).reset_stream
    case e.message
    when 'ERRORURL'
      return "AkamaiCheck: Can't get chunk list from url #{@url}, please go https://cloud.ffmpegservice.com and check it"
    when 'ERRORPLAYLIST'
      return "AkamaiCheck: Can't get video chunks from url #{@chunk_playlist_url}, please go https://cloud.ffmpegservice.com and check it"
    when 'ERRORCHUNC'
      return "AkamaiCheck: Can't get video chunk from url #{@chuck_url}, please go https://cloud.ffmpegservice.com and check it"
    else
      return "AkamaiCheck: diagnostic code error: #{e.message}, \n Urls: \n #{@url}, \n #{@chunk_playlist_url}, \n #{@chuck_url}, \n"
    end
  end
end
