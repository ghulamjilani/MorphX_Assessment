# frozen_string_literal: true

module ViewableJobs
  class RecalculateViewsJob < ApplicationJob
    def perform
      Session.find_each do |session|
        views_count = session.views.count
        unique_views_count = session.count_unique_views
        session.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      Video.find_each do |video|
        views_count = video.views.count
        unique_views_count = video.count_unique_views
        video.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      Recording.find_each do |recording|
        views_count = recording.views.count
        unique_views_count = recording.count_unique_views
        recording.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      ::Blog::Post.find_each do |blog_post|
        views_count = blog_post.views.count
        unique_views_count = blog_post.count_unique_views
        blog_post.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      Channel.find_each do |channel|
        videos_views_count = channel.videos.sum(&:views_count)
        videos_unique_views_count = channel.videos.sum(&:unique_views_count)
        recordings_views_count = channel.recordings.sum(&:views_count)
        recordings_unique_views_count = channel.recordings.sum(&:unique_views_count)
        sessions_views_count = channel.sessions.sum(&:views_count)
        sessions_unique_views_count = channel.sessions.sum(&:unique_views_count)

        views_count = videos_views_count + recordings_views_count + sessions_views_count
        unique_views_count = videos_unique_views_count + recordings_unique_views_count + sessions_unique_views_count

        channel.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      Organization.find_each do |organization|
        views_count = organization.channels.sum(&:views_count)
        unique_views_count = organization.channels.sum(&:unique_views_count)

        organization.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
        organization.user.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now)
      end

      PgSearch::Multisearch.rebuild(Session)
      PgSearch::Multisearch.rebuild(Video)
      PgSearch::Multisearch.rebuild(Recording)
      PgSearch::Multisearch.rebuild(Channel)
      PgSearch::Multisearch.rebuild(User)
    end
  end
end
