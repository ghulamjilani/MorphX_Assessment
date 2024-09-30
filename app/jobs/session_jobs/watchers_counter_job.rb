# frozen_string_literal: true

module SessionJobs
  class WatchersCounterJob < ApplicationJob
    def perform
      active_livestream_users_ids = PresenceImmersiveRoomsChannel.active_users_ids
      Room.with_open_lobby.find_each do |room|
        channel_key = PublicLivestreamRoomsChannel.subscribers_count_prefix + room.id.to_s

        count = PublicLivestreamRoomsChannel.client.get(channel_key).to_i
        room.update_column(:watchers_count, count)

        session = room.abstract_session
        SessionsChannel.broadcast 'livestream_members_count', { count: count, session_id: session.id }

        PrivateLivestreamRoomsChannel.broadcast_to room, event: 'livestream_members_count', data: { count: count }
        PublicLivestreamRoomsChannel.broadcast_to room, event: 'livestream_members_count', data: { count: count }
        PresenceImmersiveRoomsChannel.broadcast_to room, event: 'livestream_members_count', data: { count: count }

        PrivateLivestreamRoomsChannel.broadcast_to room, event: 'online_users', data: active_livestream_users_ids.with_indifferent_access[room.id.to_s].to_a.map { |id|
                                                                                        { id: id }
                                                                                      }
      end
    rescue StandardError => e
      Airbrake.notify(e)
    end
  end
end
