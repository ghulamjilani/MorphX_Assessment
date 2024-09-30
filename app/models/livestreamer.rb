# frozen_string_literal: true
class Livestreamer < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::LiveDeliveryMethodStateMachine

  belongs_to :participant, touch: true
  belongs_to :session, touch: true

  validates :session, presence: true
  validates :participant_id, uniqueness: { scope: :session_id }

  # validate :one_role_at_the_same_time, on: :create
  after_destroy :delete_room_member

  after_create do
    session.remind_about_start_at_times_via_email(user).each do |time|
      # to avoid duplicated reminders for invitees who paid for their slots
      SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, EmailOnlyFormatPolicy.to_s)

      SessionStartReminder.perform_at(time, session.id, user.id, EmailOnlyFormatPolicy.to_s)
    end

    session.remind_about_start_at_times_via_web(user).each do |time|
      # to avoid duplicated reminders for invitees who paid for their slots
      SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, WebOnlyFormatPolicy.to_s)

      SessionStartReminder.perform_at(time, session.id, user.id, WebOnlyFormatPolicy.to_s)
    end

    session.remind_about_start_at_times_via_sms(user).each do |time|
      # to avoid duplicated reminders for invitees who paid for their slots
      SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, SmsOnlyFormatPolicy.to_s)

      SessionStartReminder.perform_at(time, session.id, user.id, SmsOnlyFormatPolicy.to_s)
    end

    if Contact.where(for_user: participant.user, contact_user: session.organizer).blank?
      contact = Contact.find_or_initialize_by(for_user: participant.user, email: session.organizer.email)
      contact.contact_user = session.organizer
      contact.name = session.organizer.public_display_name
      contact.save
    end

    if Contact.where(for_user: session.organizer, contact_user: participant.user).blank?
      contact = Contact.find_or_initialize_by(for_user: session.organizer, email: participant.user.email)
      contact.contact_user = participant.user
      contact.name = participant.user.public_display_name
      contact.save
    end

    participant.user.invalidate_nearest_abstract_session_cache
    participant.user.invalidate_view_in_session_cache(session.id)
  end
  after_commit :trigger_events, on: :create

  def display_name
    Rails.cache.fetch("display_name/#{cache_key}") do
      participant.user.public_display_name
    end
  end

  # complying to Concerns::LiveDeliveryMethodStateMachine interface/conventions
  def abstract_session_model
    session
  end

  # complying to Concerns::LiveDeliveryMethodStateMachine interface/conventions
  def participant_or_co_presenter
    participant
  end

  after_destroy do
    user.invalidate_nearest_abstract_session_cache
    user.invalidate_view_in_session_cache(session.id)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, EmailOnlyFormatPolicy.to_s)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, WebOnlyFormatPolicy.to_s)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, SmsOnlyFormatPolicy.to_s)
  end

  def user
    participant.try(:user)
  end

  private

  def trigger_events
    PrivateLivestreamRoomsChannel.broadcast_to(session.room,
                                               { event: 'total_participants_count_updated',
                                                 data: { count: session.total_participants_count,
                                                         session_id: session_id } })
    PublicLivestreamRoomsChannel.broadcast_to(session.room,
                                              { event: 'total_participants_count_updated',
                                                data: { count: session.total_participants_count,
                                                        session_id: session_id } })
    SessionsChannel.broadcast 'total_participants_count_updated',
                              { count: session.total_participants_count, session_id: session_id }
  end

  def one_role_at_the_same_time
    return if Rails.env.test? && ENV['SKIP_OVERLAP_CHECK']

    if (abstract_session = user.participate_between(session.start_at, session.end_at).first)
      message = I18n.t('activerecord.errors.messages.one_role_at_the_same_time',
                       name: abstract_session.title.to_s,
                       link: abstract_session.relative_path,
                       model: I18n.t("activerecord.models.#{abstract_session.class.to_s.downcase}")).html_safe
      errors.add(:base, message)
    end
  end

  def delete_room_member
    RoomMember.find_by(abstract_user: user, kind: RoomMember::Kinds::LIVESTREAMER, room: session.room).try(:delete)
  end
end
