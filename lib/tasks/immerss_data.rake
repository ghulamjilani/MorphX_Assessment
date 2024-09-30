# frozen_string_literal: true

namespace :immerss_data do
  namespace :sync do
    desc "Sync user channels and it's sessions+room+videos"
    task :channels, %i[user_id beginning_from ch_limit s_limit] => [:environment] do |_task, args|
      # download data
      system("curl -X GET \"https://f5415d16254a4e5cbc81a6c7e338f312:cb98c0da3fbc08a943dafedd451124e5@immerss.live/api_portal/system/migrate/#{args[:user_id]}.json?pretty=true\" > user_#{args[:user_id]}_channels.json")

      @data = JSON.parse(File.read(Rails.root.join("user_#{args[:user_id]}_channels.json")))
      # deep replace id with old_id
      @data = @data.deep_transform_keys { |key| ((key == 'id') ? 'old_id' : key) }
      @beginning_from = begin
        Date.parse(args[:beginning_from])
      rescue StandardError
        Date.today.months_ago(1)
      end
      @user = User.find(@data['user']['old_id'])
      p "-----------> User: {id: #{@user.id}, display_name: #{@user.display_name}}"

      # channels --------------------------------------
      channels_stats = {
        total: @data['user']['channels'].count,
        existed: 0,
        created: 0,
        errors: 0,
        sessions_stats: {
          total: 0,
          skipped: 0,
          existed: 0,
          created: 0,
          errors: 0
        },
        videos_stats: {
          total: 0,
          existed: 0,
          created: 0,
          errors: 0
        }
      }

      @data['user']['channels'].map.with_index do |channel_data, ch_index|
        p "------------------------------------------->>> channel_data {old_id: #{channel_data['old_id']}, title: #{channel_data['title']}, created_at: #{channel_data['created_at']}}"

        # no skips

        # find or create channel
        date = DateTime.parse(channel_data['created_at'])
        channel = @user.channels.where('(channels.old_id = ? or channels.id = ?)', channel_data['old_id'],
                                       channel_data['old_id']).where(created_at: (date - 1.minute..date + 1.minute)).last

        if channel.present?
          p "--->> Channel is already existed {id: #{channel.id}, old_id: #{channel['old_id']}}"
          channels_stats[:existed] = channels_stats[:existed] + 1
        else
          p '--->> Channel creation ... ++++++++++'
          channel = @user.channels.build(channel_data.except('sessions'))
          if channel.save
            channels_stats[:created] = channels_stats[:created] + 1
          else
            p channel.errors.details
            channels_stats[:errors] = channels_stats[:errors] + 1
          end
        end

        if channel.persisted?

          # sessions --------------------------------------
          channel_data['sessions'].map.with_index do |session_data, s_index|
            p "-------------------------->>> session_data {old_id: #{session_data['old_id']}, title: #{session_data['title']}, created_at: #{session_data['created_at']}}"
            channels_stats[:sessions_stats][:total] = channels_stats[:sessions_stats][:total] + 1

            # skipping sessions
            end_time = Date.parse(session_data['start_at']) + session_data['duration'].minutes
            skip_reason = ''
            if !session_data['room']
              skip_reason = 'no room'
            elsif end_time > Time.now
              skip_reason = 'session is not started yet'
            elsif Date.parse(session_data['created_at']) < @beginning_from
              skip_reason = 'session is before needed period'
            end
            if skip_reason.present?
              p "---> skipping as #{skip_reason}"
              channels_stats[:sessions_stats][:skipped] = channels_stats[:sessions_stats][:skipped] + 1
              next
            end

            # find or create session + room

            date = DateTime.parse(session_data['created_at'])
            session = channel.sessions.where('(old_id = ? or id = ?)', session_data['old_id'],
                                             session_data['old_id']).where(created_at: (date - 1.minute..date + 1.minute)).last
            if session.present?
              p "--->> Session is already existed {id: #{session.id}, old_id: #{session.old_id}}"
              channels_stats[:sessions_stats][:existed] = channels_stats[:sessions_stats][:existed] + 1
            else
              p '--->> Session creation... ++++++++++'
              session_data['recurring_settings'] =
                ActiveSupport::HashWithIndifferentAccess.new(session_data['recurring_settings'])
              session = channel.sessions.build(session_data.except('room'))
              session.build_room(session_data['room'].except('videos'))
              if session.save(validate: false)
                channels_stats[:sessions_stats][:created] = channels_stats[:sessions_stats][:created] + 1
              else
                p session.errors.details
                channels_stats[:sessions_stats][:errors] = channels_stats[:sessions_stats][:errors] + 1
              end
            end

            # videos ----------------------------------
            session_data['room']['videos'].map do |video_data|
              p "------------>>> video_data {old_id: #{video_data['old_id']}, created_at: #{video_data['created_at']}, hls_main: #{video_data['hls_main']}}"
              channels_stats[:videos_stats][:total] = channels_stats[:videos_stats][:total] + 1

              # no skips

              # find+update or create video
              date = DateTime.parse(video_data['created_at'])
              video = session.room.videos.where('(old_id = ? or id = ?)', video_data['old_id'],
                                                video_data['old_id']).where(created_at: (date - 1.minute..date + 1.minute)).last
              if video.present?
                p "--->> Video is already existed {id: #{video.id}, old_od: #{video.old_id}}"
                channels_stats[:videos_stats][:existed] = channels_stats[:videos_stats][:existed] + 1
              else
                p '--->> Video creation... ++++++++++'
                video_data['status'] = 'downloaded'
                video = session.room.videos.build(video_data)
                if video.save
                  channels_stats[:videos_stats][:created] = channels_stats[:videos_stats][:created] + 1
                else
                  p video.errors.details
                  channels_stats[:videos_stats][:errors] = channels_stats[:videos_stats][:errors] + 1
                end
              end
              p '----- end video ---------------------------------------'
            end
            p '----- end session ------------------------------------------------------'
            break if (s_index + 1) == args[:s_limit].to_i
          end
        end
        p '------ end channel -------------------------------------------------------------------------------------'
        break if (ch_index + 1) == args[:ch_limit].to_i
      end
      p '---------------------------Stats-----------------------------'
      p channels_stats
    ensure
      FileUtils.rm_rf(Rails.root.join("user_#{args[:user_id]}_channels.json"))
    end
  end
end
