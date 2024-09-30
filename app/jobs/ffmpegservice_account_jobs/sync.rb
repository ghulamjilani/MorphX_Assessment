# frozen_string_literal: true

module FfmpegserviceAccountJobs
  class Sync < ApplicationJob
    def perform(ffmpegservice_account_id = nil)
      if ffmpegservice_account_id.nil?
        ids = FfmpegserviceAccount.where('updated_at < ?',
                                 Time.now - 1.hour).where.not(organization_id: nil).order(updated_at: :asc).first(58).pluck(:id)

        ids.each.with_index do |id, index|
          FfmpegserviceAccountJobs::Sync.perform_at(index.minute.from_now, id)
        end and return
      end

      return unless (wa = FfmpegserviceAccount.find_by(id: ffmpegservice_account_id))

      client = Sender::Ffmpegservice.client(account: wa)
      return unless (transcoder = client.get_transcoder(nil, { expected_status: [200, 422, 500] }).presence)

      wa.stream_id            =  transcoder[:id]
      wa.stream_name          =  transcoder[:stream_name]
      wa.authentication       =  !transcoder[:disable_authentication]
      wa.username             =  transcoder[:username]
      wa.password             =  transcoder[:password]
      wa.transcoder_type      =  transcoder[:transcoder_type]
      wa.delivery_method      =  transcoder[:delivery_method]
      wa.idle_timeout         =  transcoder[:idle_timeout]
      wa.sdp_url              =  "wss://#{transcoder[:domain_name]}/webrtc-session.json"
      wa.application_name     =  transcoder[:application_name]
      wa.protocol             =  transcoder[:protocol]
      wa.playback_stream_name =  transcoder[:playback_stream_name]
      hls_url = if !wa.sandbox &&
                   (stream_target_id = transcoder[:outputs].find do |output|
                                         output[:output_stream_targets].present?
                                       end&.dig(:output_stream_targets, 0, :stream_target_id)) &&
                   (fastly = client.stream_target_fastly(stream_target_id))
                  fastly.dig(:playback_urls, :hls, 0, :url)
                else
                  transcoder.dig(:direct_playback_urls, :hls, 0, :url)
                end
      wa.hls_url = hls_url
      if wa.changed?
        Airbrake.notify(
          'Found unsynced FfmpegserviceAccount, transcoder values are saved to FfmpegserviceAccount',
          parameters: {
            wa_id: wa.id,
            changes: wa.changes
          }
        )
      end
      wa.updated_at = Time.now # set updated_at in order to mark FfmpegserviceAccount as checked anyway, even if no attribute was changed
      wa.save!
    end
  end
end
