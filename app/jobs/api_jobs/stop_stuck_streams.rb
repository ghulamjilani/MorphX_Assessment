# frozen_string_literal: true

class ApiJobs::StopStuckStreams < ApplicationJob
  def perform()
    client = Sender::Ffmpegservice.client(sandbox: %w[qa production].exclude?(Rails.env))
    streams = client.transcoders_usage(30.seconds.ago, Time.now)[:transcoders].to_a.each do |transcoder|
      wa = FfmpegserviceAccount.find_by(stream_id: transcoder[:id])
      if wa.present? && should_be_inactive?(wa) && (!Rails.env.development? || !wa.sandbox)
        client = Sender::Ffmpegservice.client(account: wa)
        transcoder_state = client.state_transcoder.to_h.with_indifferent_access
        state = transcoder_state[:state]
        # FfmpegserviceStreamMailer.stream_stopped(wa.id, Time.now.utc.to_s).deliver_later
        # Sender::Ffmpegservice.client(account: wa).stop_stream
        if state != 'stopped'
          ffmpegservice_project_id = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account,
                                                                       :project_id) || '{project_id}'

          Sender::Slack.notify("#{Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :prefix)} \n
            Stream id '#{transcoder[:id]}' is active on ffmpegservice but is supposed to be inactive. \n
                               #{transcoder[:name]} \n
            Transcoder state: #{state}\n
            Transcoder uptime id: #{transcoder_state[:uptime_id]}\n
            FfmpegserviceAccount: #{ENV['HOST']}/service_admin_panel/ffmpegservice_accounts/#{wa.id} \n
            FfmpegserviceCloud: https://cloud.ffmpegservice.com/en/#{ffmpegservice_project_id}/manage/live_streams/#{transcoder[:id]} \n
            Ffmpegservice Status page: #{ENV['HOST']}/service_admin_panel/ffmpegservice_status?stream_id=#{transcoder[:id]}",
                               Sender::Slack::ISSUE_REPORT_CHANNEL_WEBHOOK_URL)
        end
      end
    end
  end

  private

  def should_be_inactive?(wa)
    running_sessions = wa.sessions.not_archived.not_cancelled.live_now.exists?
    running_previews = wa.stream_previews.not_finished.exists?
    running_sessions.blank? && running_previews.blank?
  end
end
