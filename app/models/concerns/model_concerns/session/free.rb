# frozen_string_literal: true

module ModelConcerns::Session::Free
  extend ActiveSupport::Concern

  included do
    has_many :free_trial_immersive_participants, lambda {
                                                   where(session_participations: { free_trial: true })
                                                 }, through: :session_participations, source: :participant
    has_many :free_trial_livestream_participants, lambda {
                                                    where(livestreamers: { free_trial: true })
                                                  }, through: :livestreamers, source: :participant

    scope :free_of_any_type, lambda {
                               where('free_trial_for_first_time_participants IS TRUE OR requested_free_session_satisfied_at IS NOT NULL')
                             }
    scope :free_trial_for_first_time_participants, -> { where(free_trial_for_first_time_participants: true) }
    scope :completely_free, -> { where('immersive_purchase_price = ? OR livestream_purchase_price = ?', 0, 0) }

    # before_save :sanitize_requested_free_session_reason
    before_validation :granted_free_session_before_validation, if: :requested_free_session_just_got_granted?

    after_commit :after_save_status_modification, on: %i[create update]

    # validates :requested_free_session_reason, length: 10..500, if: -> (s) do
    #   if s.requested_free_session == true
    #     # IMD-276
    #     if !s.private || s.private && s.organizer && (s.organizer.can_create_free_private_sessions_without_permission || s.organizer.free_private_sessions_without_admin_approval_left_count > 0)
    #       false
    #     elsif s.organizer && s.organizer.presenter && !s.organizer.can_publish_n_free_sessions_without_admin_approval.zero?
    #       channel_ids = s.organizer.presenter.channels.pluck(:id)
    #
    #       Session
    #         .where(id: channel_ids)
    #         .where('immersive_purchase_price = 0 OR livestream_purchase_price = 0')
    #         .count >= s.organizer.can_publish_n_free_sessions_without_admin_approval
    #     else
    #       true
    #     end
    #   else
    #     false
    #   end
    # end
    validates :requested_free_session_declined_with_message, presence: true, if: proc { |s|
                                                                                   s.status.to_s == ::Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
                                                                                 }

    validate :immersive_free_slots_compliance, if: :free_trial_for_first_time_participants?
    validate :livestream_free_slots_compliance, if: :free_trial_for_first_time_participants?

    before_validation do
      self.livestream_purchase_price = nil if @livestream == false
      self.immersive_purchase_price  = nil if @immersive == false
      self.recorded_purchase_price   = nil if @record == false

      # NOTE: this attr_writer is set only in create/update controller actions upon saving
      # if it is nil, then just ignore it - see sessions_controller#session_params
      if immersive_free
        self.immersive_purchase_price = 0
        self.immersive_free_slots = nil
      end
      if livestream_free
        self.livestream_purchase_price = 0
        self.livestream_free_slots = nil
      end
      self.recorded_purchase_price = 0 if recorded_free

      # if free_trial_for_first_time_participants == true
      #   self.requested_free_session_reason = nil
      # end

      # NOTE: this attr_writer is set only in create/update controller actions upon saving
      # if it is nil, then just ignore it - see sessions_controller#session_params
      unless immersive_delivery_method?
        self.max_number_of_immersive_participants = nil
        self.immersive_type                       = nil
        self.immersive_purchase_price             = nil
        self.immersive_free_slots                 = nil
        self.immersive_free                       = false
      end

      # NOTE: this attr_writer is set only in create/update controller actions upon saving
      # if it is nil, then just ignore it - see sessions_controller#session_params
      unless livestream_delivery_method?
        self.livestream_purchase_price = nil
        self.livestream_free_slots     = nil
        self.livestream_free           = false
      end

      if !immersive_delivery_method? && !livestream_delivery_method?
        self.min_number_of_immersive_and_livestream_participants = nil
      end

      if livestream_delivery_method? && (min_number_of_immersive_and_livestream_participants.nil? || min_number_of_immersive_and_livestream_participants < 2)
        self.min_number_of_immersive_and_livestream_participants = 1
      end

      if immersive_delivery_method? && max_number_of_immersive_participants.nil? # || max_number_of_immersive_participants < min_number_of_immersive_and_livestream_participants
        self.max_number_of_immersive_participants = 5
      end
    end
  end

  # NOTE: that session may have free + non-free delivery method #1858
  def completely_free?
    requested_free_session_satisfied_at.present? || immersive_free || livestream_free
  end

  private

  def after_save_status_modification
    if livestream_delivery_method? || !immersive_free || booking.present?
      prev_status = status
      update_column(:status, ::Session::Statuses::PUBLISHED)
      if [::Session::Statuses::REQUESTED_FREE_SESSION_PENDING, ::Session::Statuses::REQUESTED_FREE_SESSION_REJECTED].include?(prev_status)
        SessionJobs::NotifyUnnotifiedInvitedParticipantsJob.perform_async(id)
      end
    elsif requested_free_session_just_got_granted?
      requested_free_session_just_got_granted
    elsif requested_free_session_just_got_rejected?
      requested_free_session_just_got_rejected
    elsif requested_free_session_just_got_published?
      SessionJobs::NotifyUnnotifiedInvitedParticipantsJob.perform_async(id)
    elsif ((status != 'unpublished' && !saved_changes?) || (saved_changes.keys.size == 1 && saved_changes.keys.first == 'updated_at')) || [::Session::Statuses::REQUESTED_FREE_SESSION_PENDING, ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED].include?(status)
      if reload.booking.present?
        update_column(:status, ::Session::Statuses::PUBLISHED)
      end
    elsif private? && immersive_free && (organizer.can_create_free_private_sessions_without_permission? ||
      (organizer.free_private_interactive_without_admin_approval_left_count + 1).positive?)

      update_column(:status, ::Session::Statuses::PUBLISHED)

      SessionMailer
        .free_session_was_approved_automatically(id, FreeSessionPublishedAutomaticallyReasons::APPROVED_PRIVATE_AUTOMATICALLY_BECAUSE_OF_PREFERENCE)
        .deliver_later
    elsif private? && immersive_free && (!organizer.can_create_free_private_sessions_without_permission? ||
      (organizer.free_private_interactive_without_admin_approval_left_count + 1) < 1)

      update_column(:status, ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING)
      SessionMailer.requested_free_session_submitted_for_review(id).deliver_later
    else
      update_column(:status, ::Session::Statuses::PUBLISHED)
    end
  end

  def granted_free_session_before_validation
    self.requested_free_session_satisfied_at = Time.now

    self.immersive_purchase_price  = 0 unless immersive_purchase_price.nil?
    self.livestream_purchase_price = 0 unless livestream_purchase_price.nil?
  end

  def requested_free_session_just_got_granted
    # solves the problem when presenter promised to pay for co-presenter
    # and then requested a free session
    organizer_abstract_session_pay_promises.destroy_all

    session_invited_immersive_co_presenterships.where(invitation_sent_at: nil).each do |sicp|
      SessionMailer.co_presenter_invited_to_session(sicp.session_id, sicp.presenter_id).deliver_later

      sicp.touch :invitation_sent_at
    end

    SessionMailer.requested_free_session_just_got_granted(id).deliver_later

    if publish_after_requested_free_session_is_satisfied_by_admin
      # the reason  why this is extracted into job is to solve #1668
      # more reliable/simple way to separate 2 events:
      # approving free session with "publish immediately" option
      # approving free session without "publish immediately" option
      # without this fix *just_got_* checks are not reliable/clear enough
      PublishFreeSessionThatJustGotApproved.perform_at(3.seconds.from_now, id)
    else
      SessionMailer.publish_reminder(id).deliver_later
    end
  end

  def requested_free_session_just_got_rejected
    SessionMailer.requested_free_session_just_got_rejected(id).deliver_later
  end

  # NOTE: - not via state_machine because status is set from admin interface, not via state_machine event
  def requested_free_session_just_got_granted?
    saved_change_to_status? && status == ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED
  end

  # NOTE: - not via state_machine because status is set from admin interface, not via state_machine event
  def requested_free_session_just_got_rejected?
    saved_change_to_status? && status == ::Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
  end

  def requested_free_session_just_got_published?
    saved_change_to_status? && status_before_last_save == ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED && status == ::Session::Statuses::PUBLISHED
  end

  # def sanitize_requested_free_session_reason
  #   self.requested_free_session_reason = nil if @requested_free_session == false
  # end

  def immersive_free_slots_compliance
    return unless immersive_delivery_method?
    return if immersive_free_slots.blank?

    if immersive_free_slots.to_i > max_number_of_immersive_participants.to_i
      errors.add(:immersive_free_slots, :less_than_or_equal_to, count: max_number_of_immersive_participants.to_i)
    end

    if immersive_free_slots.to_i.negative?
      errors.add(:immersive_free_slots, :greater_than_or_equal_to, count: 0)
    end
  end

  def livestream_free_slots_compliance
    return unless livestream_delivery_method?
    return if livestream_free_slots.blank?

    if livestream_free_slots.to_i > SystemParameter.max_number_of_livestream_free_trial_slots.to_i
      errors.add(:livestream_free_slots, :less_than_or_equal_to,
                 count: SystemParameter.max_number_of_livestream_free_trial_slots.to_i)
    end

    if livestream_free_slots.to_i.negative?
      errors.add(:livestream_free_slots, :greater_than_or_equal_to, count: 0)
    end
  end
end
