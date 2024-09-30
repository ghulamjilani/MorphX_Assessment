# frozen_string_literal: true

module ModelConcerns::Session::StartAtCertainTime
  extend ActiveSupport::Concern

  def can_change_duration?
    return true unless persisted?
    return false if started? || cancelled?

    # overriden by admin
    return false if duration > organizer.can_create_sessions_with_max_duration

    payment_transactions.success.blank? && system_credit_entries.blank?
  end

  def can_change_start_at?
    return true unless persisted? # new, unsaved session
    return false if active? # prep time

    !started? && !cancelled?
  end

  included do
    after_create do
      organizer.invalidate_nearest_abstract_session_cache

      schedule_session_start_reminder_jobs
    end

    after_update do
      if saved_change_to_start_at?

        invalidate_nearest_abstract_session_cache_for_everyone_involved

        reschedule_session_start_reminder_jobs

        (session_participations + session_co_presenterships + livestreamers).flatten.each(&:await_decision_on_changed_start_at!)
      end
    end
  end

  def notify_about_changed_start_at_without_pending_stripe_refund(participant_or_presenter)
    # find all changes by TEMPORARYDISABLE
    # SessionMailer.free_abstract_session_notify_about_changed_start_at(id, participant_or_presenter).deliver_later
  end

  private

  def reschedule_session_start_reminder_jobs
    for_users = [organizer] \
                  + immersive_participants.collect(&:user) \
                  + co_presenters.collect(&:user) \
                  + session_invited_immersive_participantships.collect(&:user) \
                  + session_invited_immersive_co_presenterships.collect(&:user)

    for_users.uniq.each do |user|
      remind_about_start_at_times_via_email(user).each do |time|
        SidekiqSystem::Schedule.remove(SessionStartReminder, id, user.id, EmailOnlyFormatPolicy.to_s)
        SessionStartReminder.perform_at(time, id, user.id, EmailOnlyFormatPolicy.to_s)
      end

      remind_about_start_at_times_via_web(user).each do |time|
        SidekiqSystem::Schedule.remove(SessionStartReminder, id, user.id, WebOnlyFormatPolicy.to_s)
        SessionStartReminder.perform_at(time, id, user.id, WebOnlyFormatPolicy.to_s)
      end

      remind_about_start_at_times_via_sms(user).each do |time|
        SidekiqSystem::Schedule.remove(SessionStartReminder, id, user.id, SmsOnlyFormatPolicy.to_s)
        SessionStartReminder.perform_at(time, id, user.id, SmsOnlyFormatPolicy.to_s)
      end
    end
  end

  alias_method :schedule_session_start_reminder_jobs, :reschedule_session_start_reminder_jobs
end
