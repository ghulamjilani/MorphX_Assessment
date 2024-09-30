# frozen_string_literal: true

# require Rails.root.join('lib/immerss/api/immersive').to_s
class ApiJobs::StopSession < ApplicationJob
  sidekiq_options queue: :critical

  def perform(room_id)
    debug_logger('stop room', room_id)
    if (room = Room.find_by(id: room_id))
      debug_logger('stopping room', room_id)
      Control::Room.new(room).stop
      room.abstract_session.update_columns(stop_reason: 'scheduled_stop')
    else
      debug_logger('room not found', room_id)
    end
  end
end
