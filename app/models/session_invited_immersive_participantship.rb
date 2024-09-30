# frozen_string_literal: true
class SessionInvitedImmersiveParticipantship < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActsAsInvitableAbstractSessionPerson
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :participant, touch: true
  belongs_to :session, touch: true

  validates :participant_id, uniqueness: { scope: :session_id, message: 'has already been invited' }, if: :session

  validate :not_paid_participant_yet, if: :session, on: :create
  validate :not_co_presenter, on: :create, if: :session
  validate :not_invited_co_presenter, on: :create, if: :session
  validate :not_organizer, if: :session, on: :create
  validate :single_participant_at_max, if: :one_on_one_session?
  validate :session_participants_count, if: :session, on: :create

  after_update :notify_organizer_about_accepted_invitation, if: :invitation_just_got_accepted?
  after_update :notify_organizer_about_rejected_invitation, if: :invitation_just_got_rejected?
  after_update :cable_notification_status_changed, if: :saved_change_to_status?

  after_destroy do
    if session.published?
      SessionMailer.participant_rejected_from_session(session.id, participant.id).deliver_later
    end
  end

  def user
    @user ||= participant.user
  end

  def user_id
    @user_id ||= participant.user_id
  end

  def model
    session
  end

  def room_member_role
    RoomMember::Kinds::PARTICIPANT
  end

  def email
    user.try(:email)
  end

  private

  def notify_organizer_about_accepted_invitation
    Immerss::SessionMultiFormatMailer.new.user_accepted_your_session_invitation(session.id, participant.user_id).deliver
  end

  def notify_organizer_about_rejected_invitation
    Immerss::SessionMultiFormatMailer.new.user_rejected_your_session_invitation(session.id, participant.user_id).deliver
  end

  def invitation_just_got_accepted?
    saved_change_to_status? && status_change == [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                                                 ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED]
  end

  def invitation_just_got_rejected?
    saved_change_to_status? && status_change == [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                                                 ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED]
  end

  def not_invited_co_presenter
    presenter = participant.user.presenter
    # not relying on SQL here becuase session is not saved yet and it returns nil otherwise
    if presenter.present? && session.session_invited_immersive_co_presenterships.select do |p|
         !p.marked_for_destruction? && p.pending? && p.presenter == presenter
       end.present?
      errors.add(:base, 'participant is already invited as co-presenter to the session')
    end
  end

  def single_participant_at_max
    statuses = [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED]

    if session.session_invited_immersive_participantships.count do |session_invited_immersive_participantship|
         statuses.include?(session_invited_immersive_participantship.status)
       end > 1
      errors.add(:base, 'only one participant could be invited')
    end
  end

  def one_on_one_session?
    session.present? && session.immersive_type == Session::ImmersiveTypes::ONE_ON_ONE
  end

  def not_paid_participant_yet
    if session.has_immersive_participant?(participant_id)
      errors.add(:base, 'Invited participant is already confirmed as participant of the session')
    end
  end

  def not_co_presenter
    if session.has_co_presenter?(participant.user.presenter_id)
      errors.add(:base, 'Invited participant is already confirmed as co-presenter of the session')
    end
  end

  def not_organizer
    if session.organizer == participant.user
      errors.add(:base, 'Organizer could not be invited as participant')
    end
  end

  def session_participants_count
    return unless session.immersive_delivery_method?

    max_count = [
      session.max_number_of_immersive_participants_with_sources.to_i, # platform(webrtcservice/zoom) limit
      session.max_number_of_immersive_participants.to_i # number of session slots
    ].min
    total_count = session.session_invited_immersive_participantships.size
    unless total_count <= max_count # (49/99 participants + 1 presenter)
      session.errors.add(:interactive_participants_count,
                         I18n.t('controllers.sessions.max_immersive_participations_error', max_count: max_count.to_s,
                                                                                           total_count: total_count.to_s))
    end
  end

  def cable_notification_status_changed
    return if session&.room.blank?

    PresenceSourceRoomsChannel.broadcast_to session.room, event: 'immersive_participantship_status_changed',
                                                          data: { status: status, user_id: participant.user_id }
  end
end
