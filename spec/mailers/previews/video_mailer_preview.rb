# frozen_string_literal: true

class VideoMailerPreview < ApplicationMailerPreview
  def cleanup_notification
    user_id = User.order('RANDOM()').first.id
    video_ids = Video.joins(:room).joins(%(INNER JOIN sessions ON sessions.id = rooms.abstract_session_id AND rooms.abstract_session_type = 'Session'))
                     .order('RANDOM()').first(3).pluck(:id)
    VideoMailer.cleanup_notification(user_id: user_id, video_ids: video_ids, time_interval: 1)
  end

  def ready
    video_id = Video.joins(:room).joins(%(INNER JOIN sessions ON sessions.id = rooms.abstract_session_id AND rooms.abstract_session_type = 'Session'))
                    .order('RANDOM()').first.id
    VideoMailer.ready(video_id)
  end

  def uploaded
    video_id = Video.joins(:room).joins(%(INNER JOIN sessions ON sessions.id = rooms.abstract_session_id AND rooms.abstract_session_type = 'Session'))
                    .order('RANDOM()').first.id
    VideoMailer.uploaded(video_id)
  end
end
