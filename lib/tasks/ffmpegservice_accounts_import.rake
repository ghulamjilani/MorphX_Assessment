# frozen_string_literal: true

namespace :ffmpegservice_accounts do
  desc 'Import existing WA[stream_id,organization_id,user_id,current_service]: RAILS_ENV=development bundle exec rake ffmpegservice_accounts:import[01cv6dv5,1207,1,main]'
  task :import, %i[stream_id organization_id user_id current_service] => [:environment] do |_task, args|
    User.find(args[:user_id]) if args[:user_id].present?
    Organization.find(args[:organization_id]) if args[:organization_id].present?

    client = Sender::Ffmpegservice.new(sandbox: false, stream_id: args[:stream_id].to_s.strip)

    livestream = client.livestream
    puts livestream.to_json
    connection_info = livestream[:source_connection_information] || {}

    new_attributes = {
      hls_url: livestream[:player_hls_playback_url],
      stream_status: 'off',
      stream_id: livestream[:id],
      sandbox: false,
      transcoder_type: livestream[:transcoder_type],
      delivery_method: livestream[:delivery_method],
      name: livestream[:name],
      idle_timeout: 1200,
      user_id: args[:user_id],
      organization_id: args[:organization_id]
    }

    current_service = if args[:current_service].present?
                        args[:current_service]
                      elsif livestream[:delivery_method] == 'pull'
                        'ipcam'
                      else
                        'rtmp'
                      end

    if connection_info.present?
      new_attributes.merge!({
                              server: connection_info[:primary_server],
                              port: connection_info[:host_port],
                              stream_name: connection_info[:stream_name],
                              authentication: !connection_info[:disable_authentication],
                              username: connection_info[:username],
                              password: connection_info[:password],
                              source_url: connection_info[:source_url]
                            })
    end
    ffmpegservice_account = FfmpegserviceAccount.find_by(stream_id: new_attributes[:stream_id]) if new_attributes[:stream_id]
    if ffmpegservice_account.present?
      ffmpegservice_account.update(new_attributes)
      puts "Existing FfmpegserviceAccount ##{ffmpegservice_account.id}"
    else
      ffmpegservice_account = FfmpegserviceAccount.create!(new_attributes)
      puts "New FfmpegserviceAccount ##{ffmpegservice_account.id}"
    end
    ffmpegservice_account.update_columns(custom_name: ffmpegservice_account.default_custom_name, current_service: current_service)
  end
end
