# frozen_string_literal: true

class ApiJobs::AutoStartSession < ApplicationJob
  sidekiq_options queue: :critical

  def perform(room_id)
    debug_logger('start room', room_id)

    return unless (room = Room.find_by(id: room_id) || !room.autostart || !room.awaiting?)
    return if Time.now > room.actual_end_at || room.abstract_session.stopped_at.present?

    debug_logger('starting room', room_id)

    room_control = Control::Room.new(room)
    room.room_members.find_or_create_by(abstract_user: room.presenter_user, kind: 'presenter')
    room_control.start
  end
end
