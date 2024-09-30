# frozen_string_literal: true

envelope json do
  json.array! @streams do |session|
    attributes = url_attrs(session)
    json.type                         attributes[:type]
    json.status                       attributes[:status]
    json.id                           session.id
    json.small_cover_url              session.small_cover_url
    json.can_share                    can?(:share, session)
    json.room_id                      session.room.try(:id)
    json.start_at                     session.start_at.to_fs(:rfc3339)
    json.autostart                    session.autostart
    json.immersive_purchase_price     session.immersive_purchase_price
    json.livestream_purchase_price    session.livestream_purchase_price
    json.service_type                 session.room&.service_type
    json.immersive_free               session.immersive_free?
    json.livestream_free              session.livestream_free?
    json.line_slots                   session.line_slots_left.to_i
    json.title                        session.title || session.always_present_title
    json.public_display_name          session.organizer.public_display_name
    json.total_participants_count     short_number(session.total_participants_count)
    json.start_at                     session.start_at.to_fs(:rfc3339)
    json.can_remind_me                can?(:toggle_remind_me_session, session)
    json.session_reminders            current_user.session_reminders.exists?(session: session)
    json.can_access_as_subscriber     can?(:access_as_subscriber, session)
    json.can_join_as_participant      can?(:join_as_participant, session)
    json.can_join_as_livestreamer     can?(:join_as_livestreamer, session)
    json.can_join_as_presenter        session.organizer.id == current_user.id
    json.can_view_free_livestream     can?(:view_free_livestream, session)
    json.upcoming                     session.upcoming?
    json.in_progress                  session.in_progress?
    json.running                      session.running?
    json.duration                     session.duration
    json.portal_url                   session.short_url
    json.watchers_count               session.room&.watchers_count || 0
  end
end
