# frozen_string_literal: true

module ControllerConcerns::LatestNotifications
  extend ActiveSupport::Concern

  included do
    before_action :fetch_latest_notifications, if: :user_signed_in?
    before_action :fetch_upcoming_sessions_for_user
  end

  def fetch_latest_notifications
    @latest_notifications = current_user.reminder_notifications.preload(:receipts).limit(5)
  end

  def fetch_upcoming_sessions_for_user
    gon.upcoming_livestream_channels = []
    start_at_from = Time.now.beginning_of_day
    start_at_to = start_at_from + 1.day

    session_ids = Session.upcoming.not_stopped.not_cancelled.is_public.published.where(start_at: (start_at_from..start_at_to))
                         .where(livestream_free: true, age_restrictions: [nil, 0]).pluck(:id)
    more_ids = if user_signed_in?
                 participant = current_user.participant
                 if participant.present?
                   Session.upcoming.not_stopped.not_cancelled.where(start_at: (start_at_from..start_at_to))
                          .joins(livestreamers: :participant)
                          .joins(:room)
                          .where(participants: { id: participant.id }).pluck(:id)
                 else
                   []
                 end
               else
                 []
               end
    session_ids = (session_ids + more_ids).uniq
    rooms = Room.where(abstract_session_type: 'Session', abstract_session_id: session_ids).preload(:abstract_session)
    gon.upcoming_livestream_channels = rooms.map do |room|
      {
        channel: ((can?(:view_livestream_as_guest, room.abstract_session) ||
            can?(:view_free_livestream, room.abstract_session) ||
            can?(:join_as_livestreamer,
                 room.abstract_session)) ? room.livestream_channel : room.public_livestream_channel),
        relative_path: room.abstract_session.relative_path
      }
    end

    # if user_signed_in?
    #   participant = current_user.participant
    #   rooms = if participant.present?
    #             ids = Session.upcoming.not_stopped.not_cancelled.where(start_at: (start_at_from..start_at_to)).
    #                 joins(livestreamers: :participant).
    #                 joins(:room).
    #                 where(participants: {id: participant.id}).pluck(:id)
    #             Room.where(abstract_session_type: 'Session', abstract_session_id: ids).preload(:abstract_session)
    #           else
    #             []
    #           end
    #
    #   gon.upcoming_livestream_channels = rooms.map { |room| {channel: room.livestream_channel, relative_path: room.abstract_session.relative_path} }
    # else
    #   ids = Session.upcoming.not_stopped.not_cancelled.is_public.published.where(start_at: (start_at_from..start_at_to)).
    #       where(livestream_free: true, age_restrictions: [nil, 0]).pluck(:id)
    #   rooms = Room.where(abstract_session_type: 'Session', abstract_session_id: ids).preload(:abstract_session)
    #   gon.upcoming_livestream_channels = rooms.map do |room|
    #     {
    #         channel: (can?(:view_livestream_as_guest, room.abstract_session) ? room.livestream_channel : room.public_livestream_channel),
    #         relative_path: room.abstract_session.relative_path
    #     }
    #   end
    # end
  end
end
