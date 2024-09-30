# frozen_string_literal: true
class SessionReminder < ActiveRecord::Base
  belongs_to :user
  belongs_to :session

  after_create :enable
  after_destroy :disable

  def enable
    return if session.booking.present?

    session.remind_about_start_at_times_via_email(user).each do |time|
      # to avoid duplicated reminders
      remove_job EmailOnlyFormatPolicy.to_s

      SessionStartReminder.perform_at(time, session_id, user_id, EmailOnlyFormatPolicy.to_s)
    end

    session.remind_about_start_at_times_via_web(user).each do |time|
      # to avoid duplicated reminders
      remove_job WebOnlyFormatPolicy.to_s

      SessionStartReminder.perform_at(time, session_id, user_id, WebOnlyFormatPolicy.to_s)
    end

    session.remind_about_start_at_times_via_sms(user).each do |time|
      # to avoid duplicated reminders
      remove_job SmsOnlyFormatPolicy.to_s

      SessionStartReminder.perform_at(time, session_id, user_id, SmsOnlyFormatPolicy.to_s)
    end
  end

  def disable
    remove_job EmailOnlyFormatPolicy.to_s
    remove_job WebOnlyFormatPolicy.to_s
    remove_job SmsOnlyFormatPolicy.to_s
  end

  private

  def remove_job(policy)
    SidekiqSystem::Schedule.remove(SessionStartReminder, session_id, user_id, policy)
  rescue NoMethodError => e
    Rails.logger.warn e.message
    Rails.logger.warn e.backtrace
  end
end
