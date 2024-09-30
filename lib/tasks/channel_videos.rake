# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Create seed videos for channel, i.e.: 'rake db:seed:channel_videos[62]' will create videos for channel #62"
    task :channel_videos, [:channel_id] => :environment do |_task, args|
      p 'Channel id missing.' and next if (args[:channel_id]).blank?

      channel = begin
        Channel.find(args[:channel_id])
      rescue StandardError
        nil
      end

      p 'Channel not found.' and next if channel.blank?
      p 'Channel does not have available presenters' and next if channel.available_presenter_ids.blank?

      presenter = begin
        Presenter.find(channel.available_presenter_ids.first)
      rescue StandardError
        nil
      end
      p 'Channel presenter not found.' and next if presenter.blank?

      time_now = Time.now

      Timecop.travel 1.month.ago do
        20.times do |i|
          session = FactoryBot.create(:recorded_session,
                                      channel: channel,
                                      presenter: presenter,
                                      start_at: (time_now - 200.minutes - i.days),
                                      duration: (15..180).step(5).to_a.sample)
          p "Session id:#{session.id} created."
          video = FactoryBot.create(:video_published,
                                    room: session.room,
                                    duration: session.duration * 60 * 1000,
                                    show_on_profile: true)
          p "Video id:#{video.id} created."
        rescue StandardError => e
          p e.message
        end

        10.times do |i|
          session = FactoryBot.create(:recorded_session,
                                      channel: channel,
                                      presenter: presenter,
                                      start_at: (time_now - 200.minutes - i.days),
                                      duration: (15..180).step(5).to_a.sample)
          p "Session id:#{session.id} created."
        rescue StandardError => e
          p e.message
        end
      end
    end
  end
end
