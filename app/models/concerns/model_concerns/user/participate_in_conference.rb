# frozen_string_literal: true

module ModelConcerns::User::ParticipateInConference
  extend ActiveSupport::Concern

  def participate_between_by_types(start_at, end_at, skip = [])
    abstract_sessions_by_types = {}

    if presenter
      unless skip.include?('s_presenter')
        abstract_sessions_by_types[:s_presenter] = ::Room.where(presenter_user_id: id).where.not(status: 'closed')
                                                         .where(abstract_session_type: 'Session')
                                                         .where('(actual_start_at::timestamp , actual_end_at::timestamp) overlaps (:start_at::timestamp ,:end_at::timestamp)',
                                                                start_at: start_at,
                                                                end_at: end_at).preload(:abstract_session).map(&:abstract_session)
      end

      unless skip.include?('s_co_presenter')
        abstract_sessions_by_types[:s_co_presenter] = ::Session.not_cancelled.joins(session_co_presenterships: :presenter)
                                                               .joins(:room)
                                                               .where.not(rooms: { status: 'closed' })
                                                               .where(presenters: { id: presenter.id })
                                                               .where('(rooms.actual_start_at::timestamp , rooms.actual_end_at::timestamp) overlaps (:start_at::timestamp ,:end_at::timestamp)',
                                                                      start_at: start_at,
                                                                      end_at: end_at)
      end
    end

    if participant && skip.exclude?('s_participant')
      abstract_sessions_by_types[:s_participant] = ::Session.not_cancelled.joins(session_participations: :participant)
                                                            .joins(:room)
                                                            .joins('LEFT JOIN room_members ON rooms.id = room_members.room_id AND participants.user_id::varchar = room_members.abstract_user_id AND room_members.abstract_user_type = \'User\' AND room_members.banned = TRUE')
                                                            .where.not(room_members: { banned: true })
                                                            .where.not(rooms: { status: 'closed' })
                                                            .where(participants: { id: participant.id })
                                                            .where('(rooms.actual_start_at::timestamp , rooms.actual_end_at::timestamp) overlaps (:start_at::timestamp ,:end_at::timestamp)',
                                                                   start_at: start_at,
                                                                   end_at: end_at)
    end
    abstract_sessions_by_types
  end

  # skip_types= ['s_presenter', 's_participant', 's_co_presenter', 'w_participant']
  def participate_between(start_at, end_at, skip = [])
    start_at = Time.now.utc if Time.now.utc > start_at # issue 1422
    participate_between_by_types(start_at, end_at, skip).values.flatten
  end

  # FIXME: - change name because org owner does not present in most cases
  def presenting_at_sessions
    return ::Session.none if presenter.blank?

    ::Session.with_participants_count
             .where('sessions.presenter_id = :presenter_id', presenter_id: presenter.id)
             .order('sessions.start_at ASC').group('sessions.id')
             .preload(channel: %i[presenter organization], room: :abstract_session)
  end

  def sessions_presents
    channel_ids = all_channels.pluck(:id)
    ::Session.with_participants_count
             .joins(%(LEFT JOIN presenters ON presenters.id = sessions.presenter_id))
             .where(%{sessions.presenter_id = :presenter_id OR sessions.channel_id IN (:channel_ids)},
                    presenter_id: presenter.id, channel_ids: channel_ids)
             .order(%(sessions.start_at ASC)).group(:id)
             .preload(:presenter, channel: %i[presenter organization], room: :abstract_session)
  end

  def co_presenting_or_invited_to_sessions
    return ::Session.none if presenter.blank?

    ::Session.published
             .joins(%( LEFT OUTER JOIN "session_co_presenterships" ON "session_co_presenterships"."session_id" = "sessions"."id" ))
             .joins(%( LEFT OUTER JOIN "session_invited_immersive_co_presenterships" ON "session_invited_immersive_co_presenterships"."session_id" = "sessions"."id" ))
             .where("session_co_presenterships.presenter_id = :presenter_id OR
             (session_invited_immersive_co_presenterships.presenter_id = :presenter_id AND session_invited_immersive_co_presenterships.status <> :status)", presenter_id: presenter.id, status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
             .order('sessions.start_at ASC')
             .group('sessions.id')
             .preload(channel: :presenter, room: :abstract_session)
  end

  def participating_or_invited_to_sessions
    return ::Session.none if participant.blank?

    ::Session.published
             .where("id IN(SELECT session_participations.session_id FROM session_participations where participant_id = #{participant_id}
                 UNION ALL SELECT livestreamers.session_id FROM livestreamers where participant_id = #{participant_id}
                 UNION ALL SELECT session_invited_immersive_participantships.session_id FROM session_invited_immersive_participantships WHERE participant_id = #{participant_id} AND status <> '#{ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED}'
                 UNION ALL SELECT session_invited_livestream_participantships.session_id FROM session_invited_livestream_participantships WHERE participant_id = #{participant_id} AND status <> '#{ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED}')")
             .order(start_at: :asc)
             .preload(channel: :presenter, room: :abstract_session)
  end

  # User invited as presenter to channel. He can be a presenter of session at this channel
  # User that creates session(for now only channel owner -> [presenter.user or organization.user])
  # can select presenter from dropdown list on session's form
  def invited_channels_sessions
    return ::Session.none if presenter.blank?

    ::Session.with_participants_count
             .where(presenter_id: presenter.id)
             .order(%("sessions"."start_at" ASC))
             .group(%("sessions"."id"))
             .preload(:presenter, :channel, room: :abstract_session)
  end
end
