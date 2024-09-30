# frozen_string_literal: true

module ModelConcerns::ActsAsInvitableAbstractSessionPerson
  extend ActiveSupport::Concern

  module Statuses
    PENDING = 'pending'
    ACCEPTED = 'accepted'
    REJECTED = 'rejected'

    ALL = [PENDING, ACCEPTED, REJECTED].freeze
  end

  included do
    validates :status, presence: true, inclusion: { in: Statuses::ALL }

    before_validation :set_default_status, on: :create

    after_create :create_reminders

    after_destroy :disable_reminders

    after_update :disable_reminders, if: :invitation_just_got_rejected?

    scope :pending, -> { where(status: Statuses::PENDING) }
    scope :accepted, -> { where(status: Statuses::ACCEPTED) }
    scope :rejected, -> { where(status: Statuses::REJECTED) }

    after_initialize :set_initial_status

    def set_initial_status
      self.status ||= Statuses::PENDING
    end

    def room_member_role
      nil
    end

    state_machine :status, initial: Statuses::PENDING do
      event :accept do
        transition Statuses::PENDING => Statuses::ACCEPTED
      end

      after_transition on: :accept do |model, _transition|
        case model
        when SessionInvitedImmersiveParticipantship
          obj = model.session.session_invited_livestream_participantships.pending.first
          obj.reject! if obj.present?
        when SessionInvitedLivestreamParticipantship
          obj = model.session.session_invited_immersive_participantships.pending.first
          obj.reject! if obj.present?
        when SessionInvitedImmersiveCoPresentership
          # no additional behavior, skip it
        when ChannelInvitedPresentership
          # no additional behavior, skip it
        else
          Airbrake.notify(
            RuntimeError.new('[after_transition on: :accept] model method must be implemented in the module where in include this concern'), parameters: model.inspect
          )
        end
      end

      event :reject do
        transition Statuses::PENDING => Statuses::REJECTED
      end
    end
  end

  def disable_reminders
    case model
    when Session
      disable_session_reminders EmailOnlyFormatPolicy.to_s
      disable_session_reminders WebOnlyFormatPolicy.to_s
      disable_session_reminders SmsOnlyFormatPolicy.to_s
    when Channel
      # skip it
    when ChannelInvitedPresentership
      # No one don't want fix it, so I just skip this model
    else
      # Airbrake.notify(RuntimeError.new("[disable_reminders] model method must be implemented"), parameters: self.class.inspect)
    end
  end

  def create_reminders
    case model
    when Channel
      # no additional behavior, skip it
    when Session
      model.remind_about_start_at_times_via_email(user).each do |time|
        # to avoid duplicated reminders for invitees who paid for their slots
        disable_session_reminders EmailOnlyFormatPolicy.to_s

        SessionStartReminder.perform_at(time, model.id, user.id, EmailOnlyFormatPolicy.to_s)
      end

      model.remind_about_start_at_times_via_web(user).each do |time|
        # to avoid duplicated reminders for invitees who paid for their slots
        disable_session_reminders WebOnlyFormatPolicy.to_s

        SessionStartReminder.perform_at(time, model.id, user.id, WebOnlyFormatPolicy.to_s)
      end

      model.remind_about_start_at_times_via_sms(user).each do |time|
        # to avoid duplicated reminders for invitees who paid for their slots
        disable_session_reminders SmsOnlyFormatPolicy.to_s

        SessionStartReminder.perform_at(time, model.id, user.id, SmsOnlyFormatPolicy.to_s)
      end
    else
      Airbrake.notify(
        RuntimeError.new('[create_reminders] model method must be implemented in the module where in include this concern'), parameters: model.inspect
      )
    end
  end

  def send_firebase_notice
    model_class = model.class.to_s
    title = "New #{model_class} Invite"
    body = "#{model.organizer.public_display_name} has invited you to join the #{model_class}. "

    kind = case room_member_role
           when RoomMember::Kinds::PARTICIPANT, RoomMember::Kinds::CO_PRESENTER
             'session_invite_guest'
           else
             'session_invite_viewer'
           end

    message = {
      android: {
        priority: 'high',
        data: {
          kind: kind,
          session_id: model.id,
          session_type: model.class.to_s.downcase,
          title: title,
          body: body
        }
      },
      apns: {
        headers: {
          'apns-priority': 10
        },
        payload: {
          session_id: model.id,
          session_type: model.class.to_s.downcase,

          aps: {
            alert: {
              title: title,
              body: body
            },
            sound: 'default',
            category: kind
          }
        }
      }
    }

    Sender::FirebaseLib.send(message: message, sync: false) unless Rails.env.development?
  end

  private

  def invitation_just_got_rejected?
    saved_change_to_status? && status_change == [Statuses::PENDING, Statuses::REJECTED]
  end

  def disable_session_reminders(policy)
    SidekiqSystem::Schedule.remove(SessionStartReminder, model.id, user.id, policy)
  rescue NoMethodError => e
    Rails.logger.warn e.message
    Rails.logger.warn e.backtrace
  end

  def set_default_status
    self.status = Statuses::PENDING if status.blank?
  end
end
