# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Create seed activities for user, i.e.: 'rake db:seed:user_activities[1]' will create activities for user #1"
    task :user_activities, [:user_id] => :environment do |_task, args|
      p 'User id missing.' and next if (args[:user_id]).blank?

      current_user = begin
        User.find(args[:user_id])
      rescue StandardError
        nil
      end

      p 'User not found.' and next if current_user.blank?

      time_now = Time.now

      7.times do |i|
        3.times do
          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            user = User.not_fake.not_deleted.order('RANDOM()').limit(1).first
            if user.present?
              user.log_daily_activity(:view, owner: current_user)
              p "created view activity log for user ##{user.id}"
            end
          end

          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            organization = Organization.order('RANDOM()').limit(1).first
            if organization.present?
              organization.log_daily_activity(:view, owner: current_user)
              p "created view activity log for organization ##{organization.id}"
            end
          end

          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            channel = Channel.listed.not_archived.not_fake.order('RANDOM()').limit(1).first
            if channel.present?
              channel.log_daily_activity(:view, owner: current_user)
              p "created view activity log for channel ##{channel.id}"
            end
          end

          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            session = Session.published.finished.order('RANDOM()').limit(1).first
            if session.present?
              session.log_daily_activity(:view, owner: current_user)
              p "created view activity log for session ##{session.id}"
            end
          end

          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            video = Video.available.published.not_fake.order('RANDOM()').limit(1).first
            if video.present?
              video.log_daily_activity(:view, owner: current_user)
              p "created view activity log for video ##{video.id}"
            end
          end

          Timecop.travel (i.days + (1..23).to_a.sample.hours).ago do
            recording = Recording.available.published.order('RANDOM()').limit(1).first
            if recording.present?
              recording.log_daily_activity(:view, owner: current_user)
              p "created view activity log for recording ##{recording.id}"
            end
          end
        rescue StandardError => e
          p e.message
        end
      end
    end
  end
end
