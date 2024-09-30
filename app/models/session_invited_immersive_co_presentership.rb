# frozen_string_literal: true
class SessionInvitedImmersiveCoPresentership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActsAsInvitableAbstractSessionPerson
  include ModelConcerns::ActiveModel::Extensions

  after_create :send_firebase_notice # ActsAsInvitableAbstractSessionPerson.send_firebase_notice don't include it in to sessions invite participants users, because session should invite users after publish

  belongs_to :presenter, touch: true
  belongs_to :session, touch: true

  validates :presenter_id, uniqueness: { scope: :session_id, message: 'has already been invited' }, if: :session

  validate :not_paid_co_presenter_yet, if: :session, on: :create
  validate :not_paid_participant, on: :create, if: :session
  validate :not_invited_participant, if: :session, on: :create
  validate :not_organizer, if: :session, on: :create

  after_create do
    if session.immersive_free || session.livestream_free
      # do not notify instantly, wait until session is approved
    elsif invitation_sent_at.blank?
      SessionMailer.co_presenter_invited_to_session(session_id, presenter_id).deliver_later
      touch :invitation_sent_at
    end
  end

  after_update :notify_organizer_about_accepted_invitation, if: :invitation_just_got_accepted?
  after_update :notify_co_presenter_about_accepted_invitation, if: :invitation_just_got_accepted?

  after_update :notify_organizer_about_rejected_invitation, if: :invitation_just_got_rejected?

  after_destroy :delete_related_records

  def user
    @user ||= presenter.user
  end

  def user_id
    @user_id ||= presenter.user_id
  end

  def model
    session
  end

  def room_member_role
    RoomMember::Kinds::CO_PRESENTER
  end

  def email
    user.try(:email)
  end

  private

  def delete_related_records
    session.organizer_abstract_session_pay_promises.where(co_presenter: presenter).last.try(:destroy)
    if session.session_co_presenterships.where(presenter: presenter).last.try(:destroy)
      SessionMailer.co_presenter_rejected_from_session(session.id, presenter.id).deliver_later
    end
  end

  def notify_co_presenter_about_accepted_invitation
    SessionMailer.you_as_co_presenter_accepted_session_invitation(session.id, presenter.user_id).deliver_later
  end

  def notify_organizer_about_rejected_invitation
    Immerss::SessionMultiFormatMailer.new.user_rejected_your_session_invitation(session.id, presenter.user_id).deliver
  end

  def invitation_just_got_rejected?
    saved_change_to_status? && status_change == [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                                                 ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED]
  end

  def notify_organizer_about_accepted_invitation
    Immerss::SessionMultiFormatMailer.new.user_accepted_your_session_invitation(session.id, presenter.user_id).deliver
  end

  def invitation_just_got_accepted?
    saved_change_to_status? && status_change == [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                                                 ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED]
  end

  def not_paid_co_presenter_yet
    if session.has_co_presenter?(presenter_id)
      errors.add(:base, 'can not invited a co-presenter who already accepted invitation')
    end
  end

  def not_paid_participant
    if session.has_immersive_participant?(presenter.user.participant_id)
      errors.add(:base, 'co-presenter is already confirmed as participant of the session')
    end
  end

  def not_invited_participant
    participant = presenter.user.participant
    # not relying on SQL here becuase session is not saved yet and it returns nil otherwise
    if participant.present? && session.session_invited_immersive_participantships.select do |p|
         !p.marked_for_destruction? && p.pending? && p.participant == participant
       end.present?
      errors.add(:base, 'co-presenter is already invited as immersive participant to the session')
    elsif participant.present? && session.session_invited_livestream_participantships.select do |p|
            !p.marked_for_destruction? && p.pending? && p.participant == participant
          end.present?
      errors.add(:base, 'co-presenter is already invited as livestream participant to the session')
    end
  end

  def not_organizer
    if session.presenter == presenter
      errors.add(:base, 'Organizer could not be invited as co-presenter')
    end
  end
end
