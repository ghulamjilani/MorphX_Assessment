# frozen_string_literal: false

module EmailJobs
  class VodS3UntrackedObjectsReportJob < ApplicationJob
    def perform(email)
      return if email.blank?
      return if cancelled?

      users_folders.each do |user_id|
        process_user_folder(user_id)
      end

      SystemReportMailer.untracked_vod_objects_report(
        email,
        {
          users: @untracked_users,
          rooms: @untracked_rooms,
          videos: @untracked_videos,
          channels: @untracked_channels,
          recordings: @untracked_recordings
        }
      ).deliver_now
    end

    def process_user_folder(user_id)
      @untracked_users ||= []
      user = User.find_by(id: user_id)
      if user.blank?
        @untracked_users << user_id
        return
      end

      process_user_videos(user_id)
      process_user_recordings(user_id)
    end

    def process_user_videos(user_id)
      @untracked_rooms ||= []
      @untracked_videos ||= []
      user_rooms_folders(user_id).each do |room_id|
        room = Room.find_by(id: room_id)
        if room.blank?
          @untracked_rooms << "#{user_id}/#{room_id}"
          next
        end

        user_room_videos_objects(user_id, room_id).each do |video_folder_or_file|
          path = "#{user_id}/#{room_id}/#{video_folder_or_file}"
          @untracked_videos << path unless known_video?(user_id, room_id, video_folder_or_file)
        end
      end
    end

    def process_user_recordings(user_id)
      @untracked_channels ||= []
      @untracked_recordings ||= []
      user_channels_folders(user_id).each do |channel_id|
        channel = Channel.find_by(id: channel_id)
        if channel.blank?
          @untracked_channels << "#{user_id}/channels/#{channel_id}"
          next
        end

        user_channel_recordings_folders(user_id, channel_id).each do |object_name|
          path = "#{user_id}/channels/#{channel_id}/#{object_name}"
          @untracked_recordings << path unless known_recording?(user_id, channel_id, object_name)
        end
      end
    end

    def user_rooms_folders(user_id)
      path_root_objects(user_id).filter { |name| name.to_s.match(/\d+/) }
    end

    def user_room_videos_objects(user_id, room_id)
      path_root_objects("#{user_id}/#{room_id}")
    end

    def user_channels_folders(user_id)
      path_root_objects("#{user_id}/channels").filter { |name| name.to_s.match(/\d+/) }
    end

    def user_channel_recordings_folders(user_id, channel_id)
      path_root_objects("#{user_id}/channels/#{channel_id}").filter { |name| name.to_s.match(/\d+/) }
    end

    def users_folders
      path_root_objects('').filter { |name| name.to_s.match(/\d+/) }
    end

    def path_root_objects(path)
      return [] if Rails.env.test? || Rails.env.development? || cancelled?

      path.gsub!(%r{^/+|/+$}, '')
      path.concat('/') if path.present?
      bucket_object_keys.filter do |object_key|
        # "67920/6237/465b65f9f955de998b72ed1b4ea3668e/audio_0_1/segment-9.ts" => "67920/6237/465b65f9f955de998b72ed1b4ea3668e"
        object_key.match(%r{(#{path}[^/]+)})
      end.uniq
    end

    def bucket_object_keys
      @bucket_object_keys ||= bucket.objects({ prefix: '' }).map(&:key)
    end

    def bucket
      @bucket ||= Aws::S3::Resource.new.bucket(ENV['S3_BUCKET_VOD'].to_s)
    end

    def known_video?(user_id, room_id, object_name)
      hls_path = "/#{user_id}/#{room_id}/#{object_name}/playlist.m3u8"
      return true if Video.exists?('hls_main = :hls_path OR hls_preview = :hls_path', hls_path:)

      Video.exists?('filename = :object_name OR original_name = :object_name', object_name:)
    end

    def known_recording?(user_id, channel_id, object_name)
      hls_path = "/#{user_id}/channels/#{channel_id}/#{object_name}/playlist.m3u8"
      Recording.exists?('hls_main = :hls_path OR hls_preview = :hls_path', hls_path:)
    end

    def cancelled?
      Sidekiq.redis { |c| c.exists("cancelled-#{jid}") }
    end

    def self.cancel!(jid)
      Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
    end
  end
end
