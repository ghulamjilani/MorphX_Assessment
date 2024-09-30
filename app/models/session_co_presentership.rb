# frozen_string_literal: true
class SessionCoPresentership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::LiveDeliveryMethodStateMachine
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :presenter
  belongs_to :session, touch: true

  validates :presenter_id, uniqueness: { scope: :session_id }, if: :session

  validate :not_primary_presenter, if: :session, on: :create
  validate :not_invited_participant, if: :session, on: :create
  # validate :one_role_at_the_same_time, on: :create

  after_create :create_room_member
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

    presenter.user.invalidate_nearest_abstract_session_cache
  end

  after_commit :trigger_events, on: :create

  def display_name
    Rails.cache.fetch("display_name/#{cache_key}") do
      presenter.user.public_display_name
    end
  end

  # complying to Concerns::LiveDeliveryMethodStateMachine interface/conventions
  def abstract_session_model
    session
  end

  # complying to Concerns::LiveDeliveryMethodStateMachine interface/conventions
  def participant_or_co_presenter
    presenter
  end

  after_destroy do
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, EmailOnlyFormatPolicy.to_s)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, WebOnlyFormatPolicy.to_s)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session.id, user.id, SmsOnlyFormatPolicy.to_s)
  end

  def user
    @user ||= presenter.user
  end

  private

  def not_primary_presenter
    if session.presenter.present? && session.presenter == presenter
      errors.add(:presenter, 'could not add co-presenter who is already primary presenter')
    end
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

  def not_invited_participant
    participant = presenter.user.participant
    _status = ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED
    if participant.present? && session.session_invited_immersive_participantships.where.not(status: _status).exists?(participant: participant)
      errors.add(:presenter, 'already invited to the session as immersive participant')
    elsif participant.present? && session.session_invited_livestream_participantships.where.not(status: _status).exists?(participant: participant)
      errors.add(:presenter, 'already invited to the session as livestream participant')
    end
  end

  def trigger_events
    PresenceImmersiveRoomsChannel.broadcast_to(session.room, { event: 'new_member', data: { id: user.id } })
    PrivateLivestreamRoomsChannel.broadcast_to(session.room, { event: 'new_member', data: { id: user.id } })
  end

  def create_room_member
    RoomMember.find_or_create_by(abstract_user: user, kind: RoomMember::Kinds::CO_PRESENTER, room: session.room)
  end

  def delete_room_member
    RoomMember.find_by(abstract_user: user, kind: RoomMember::Kinds::CO_PRESENTER, room: session.room).try(:delete)
  end
end
