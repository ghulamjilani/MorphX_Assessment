# frozen_string_literal: true

namespace :sessions do
  desc 'Find and assign proper wa for sessions without wa'
  task assign_ffmpegservice_accounts: :environment do
    total = 0
    processed = 0
    failed = 0
    query = Session.finished.not_cancelled.joins(presenter: :user).where(ffmpegservice_account_id: nil).where('users.deleted IS FALSE')
    count = query.count
    query.order('created_at desc').find_each do |session|
      organization = session.channel.organization
      total += 1
      begin
        puts ''
        puts "Processing session #{session.id} (#{total}/#{count})"
        user = session.presenter.user
        unless user
          failed += 1
          puts 'ERROR: No User found'
          next
        end
        puts "User: #{user.display_name} - ##{user.id}"

        current_service = organization.wa_service_by(service_type: session.service_type)
        relation = organization.ffmpegservice_accounts.where(current_service: current_service,
                                                     transcoder_type: (organization.ffmpegservice_transcode ? 'transcoded' : 'passthrough')).order('sandbox asc')
        wa = if current_service == 'main'
               relation.find_by(user_id: user.id)
             else
               relation.first
             end

        if !wa
          puts 'matching wa NOT found, assigning new one'
          type = organization.ffmpegservice_transcode ? :paid : :free
          wa = organization.assign_ffmpegservice_account(current_service: current_service, type: type, user_id: user.id)
        else
          puts 'matching wa FOUND'
        end

        unless wa
          failed += 1
          puts 'failed to find and assign ffmpegservice account for user'
          next
        end

        session.update_columns(ffmpegservice_account_id: wa.id)
        processed += 1
        puts "Assigned ffmpegservice account ##{wa.id}"
        sleep 1
      rescue StandardError => e
        failed += 1
        puts "Exception: #{e.message}"
        puts "Presenter user ##{user.id}"
      end
    end
    puts 'Complete!'
    puts "Sessions processed: #{processed}"
    puts "Failed: #{failed}"
    puts "Total: #{total}"
  end
end
