# frozen_string_literal: true

namespace :ffmpegservice_accounts do
  desc 'Fill deafult custom name for all ffmpegservice accounts'
  task custom_name: :environment do
    FfmpegserviceAccount.find_each do |wa|
      puts ''
      puts "Processing FfmpegserviceAccount ##{wa.id}..."
      wa.update_columns(custom_name: wa.default_custom_name)
      puts wa.default_custom_name
    rescue StandardError => e
      puts "Exception: #{e.message}"
      puts "user ##{wa.user_id} organization ##{wa.organization_id}"
    end
    puts 'Complete!'
  end
end
