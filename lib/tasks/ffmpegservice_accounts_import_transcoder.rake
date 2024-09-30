# frozen_string_literal: true

namespace :ffmpegservice_accounts do
  desc 'Import existing WA by transcoder[stream_id,organization_id,user_id,current_service]: RAILS_ENV=development bundle exec rake ffmpegservice_accounts:import_transcoder[01cv6dv5,1207,1,main]'
  task :import_transcoder, %i[stream_id organization_id user_id current_service] => [:environment] do |_task, args|
    User.find(args[:user_id]) if args[:user_id].present?
    Organization.find(args[:organization_id]) if args[:organization_id].present?
    client = Sender::Ffmpegservice.new(sandbox: false, stream_id: args[:stream_id].to_s.strip)

    transcoder = client.get_transcoder
    puts transcoder.to_json
    hls_url = if (stream_target_id = transcoder[:outputs].find do |output|
                                       output[:output_stream_targets].present?
                                     end&.dig(:output_stream_targets, 0, :stream_target_id))
                fastly = client.stream_target_fastly(stream_target_id)
                fastly.dig(:playback_urls, :hls, 0, :url)
              else
                transcoder.dig(:direct_playback_urls, :hls, 0, :url)
              end

    new_attributes = {
      hls_url: hls_url,
      stream_status: 'off',
      stream_id: transcoder[:id],
      sandbox: false,
      transcoder_type: transcoder[:transcoder_type],
      delivery_method: transcoder[:delivery_method],
      stream_name: transcoder[:stream_name],
      name: transcoder[:name],
      idle_timeout: transcoder[:idle_timeout],
      user_id: args[:user_id],
      organization_id: args[:organization_id],
      sdp_url: "wss://#{transcoder[:domain_name]}/webrtc-session.json",
      application_name: transcoder[:application_name],
      protocol: transcoder[:protocol]
    }

    current_service = if args[:current_service].present?
                        args[:current_service]
                      elsif transcoder[:delivery_method] == 'pull'
                        'ipcam'
                      else
                        case transcoder[:protocol]
                        when 'rtmp'
                          'rtmp'
                        when 'rtsp'
                          'ipcam'
                        when 'webrtc'
                          'webrtc'
                        else
                          'main'
                        end
                      end

    ffmpegservice_account = FfmpegserviceAccount.find_by(stream_id: new_attributes[:stream_id]) if new_attributes[:stream_id]
    if ffmpegservice_account.present?
      ffmpegservice_account.update!(new_attributes)
      puts "Existing FfmpegserviceAccount ##{ffmpegservice_account.id}"
    else
      ffmpegservice_account = FfmpegserviceAccount.create!(new_attributes)
      puts "New FfmpegserviceAccount ##{ffmpegservice_account.id}"
    end
    ffmpegservice_account.update_columns(custom_name: ffmpegservice_account.default_custom_name, current_service: current_service)
  end
end
