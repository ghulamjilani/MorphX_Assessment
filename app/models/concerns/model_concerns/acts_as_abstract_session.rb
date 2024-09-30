# encoding: utf-8
# frozen_string_literal: true

module ModelConcerns::ActsAsAbstractSession
  extend ActiveSupport::Concern

  included do
    def model_class
      self.class.to_s.constantize
    end
    private :model_class

    has_many :reviews, as: :commentable, dependent: :destroy

    belongs_to :abstract_session_cancel_reason

    scope :cancelled, -> { where.not(cancelled_at: nil) }
    scope :not_cancelled, -> { where(cancelled_at: nil) }
    scope :upcoming, lambda {
                       where(":time_now < (start_at + (INTERVAL '1 minute' * duration))", { time_now: Time.now.utc })
                     }
    scope :finished, lambda {
                       where(":time_now > (start_at + (INTERVAL '1 minute' * duration)) OR stopped_at IS NOT NULL", { time_now: Time.now.utc })
                     }
    scope :not_finished, lambda {
                           where(":time_now < (start_at + (INTERVAL '1 minute' * duration)) AND stopped_at IS NULL", { time_now: Time.now.utc })
                         }

    validates :start_at, presence: true

    validates :abstract_session_cancel_reason, presence: true, if: :cancelled_at
    validate :complies_to_max_book_ahead_system_parameter

    validate :not_in_the_past

    after_create :schedule_jobs
    after_update :schedule_jobs, if: proc { |obj| obj.saved_change_to_start_at? || obj.saved_change_to_duration? || obj.saved_change_to_stopped_at? }
    after_update :reschedule_publish_reminder, if: proc { |obj| obj.saved_change_to_start_at? }
    after_destroy :remove_schedule_jobs
    after_commit :reschedule_publish_reminder, on: :create
  end

  def has_immersive_participant?(participant_id)
    return false if participant_id.nil?

    Rails.cache.fetch("has_immersive_participant/#{cache_key}/#{participant_id}") do
      immersive_participants.exists?(id: participant_id)
    end
  end

  def has_livestream_participant?(participant_id)
    return false if participant_id.nil?

    Rails.cache.fetch("has_livestream_participant/#{cache_key}/#{participant_id}") do
      livestreamers.exists?(participant_id: participant_id)
    end
  end

  def has_co_presenter?(presenter_id)
    return false if presenter_id.nil?

    Rails.cache.fetch("has_co_presenter/#{cache_key}/#{presenter_id}") do
      co_presenters.exists?(id: presenter_id)
    end
  end

  def reschedule_publish_reminder
    SidekiqSystem::Schedule.remove(SessionPublishReminder, id)
    [24, 12, 6, 3].each do |hrs|
      time = hrs.hours.until(start_at)
      if time > Time.zone.now
        SessionPublishReminder.perform_at(time, id)
      end
    end
  end

  def schedule_jobs
    SidekiqSystem::Schedule.remove(AbstractSessionVodIsFullyReadyStatusCheck, self.class.to_s, id)
    SidekiqSystem::Schedule.remove(CheckVodAbstractSessionEventualAvailability, self.class.to_s, id)

    AbstractSessionVodIsFullyReadyStatusCheck.perform_at(end_at, self.class.to_s, id)
    CheckVodAbstractSessionEventualAvailability.perform_at(6.hours.since(end_at), self.class.to_s, id)

    if saved_change_to_start_at?
      SidekiqSystem::Schedule.remove(InvalidateNearestUpcomingAbstractSessionCache, self.class.to_s, id)
      InvalidateNearestUpcomingAbstractSessionCache.perform_at(1.second.since(start_at), self.class.to_s, id)
    end

    # we need to update pg_search_document to remove it from search after scheduled session end, because nothing will trigger
    # pg search document update after session end in case when session is not started
    SidekiqSystem::Schedule.remove(SearchableJobs::UpdatePgSearchDocumentJob, self.class.to_s, id, { 'after_end_at' => true })
    SearchableJobs::UpdatePgSearchDocumentJob.perform_at(5.seconds.since(end_at), self.class.name, id, { 'after_end_at' => true })
  end

  def remove_schedule_jobs
    SidekiqSystem::Schedule.remove(AbstractSessionVodIsFullyReadyStatusCheck, self.class.to_s, id)
    SidekiqSystem::Schedule.remove(CheckVodAbstractSessionEventualAvailability, self.class.to_s, id)
    SidekiqSystem::Schedule.remove(InvalidateNearestUpcomingAbstractSessionCache, self.class.to_s, id)
    if is_a?(Session)
      SidekiqSystem::Schedule.remove(SessionPublishReminder, id)
      SidekiqSystem::Schedule.remove(SessionAccounting, id)
    end
  end

  def schedule_stop_no_stream_job
    return unless running? && room.active?
    return unless (stop_delay = organization.stop_no_stream_sessions.to_i).positive?
    return if end_at < stop_delay.minutes.from_now
    return if was_job_scheduled?('SessionJobs::StopNoStreamSessionJob')

    job_id = SessionJobs::StopNoStreamSessionJob.perform_at(stop_delay.minutes.from_now, id)
    job_scheduled!(job_name: 'SessionJobs::StopNoStreamSessionJob', job_id: job_id)
    notification_job_id = SessionJobs::StopNoStreamSessionNotificationJob.perform_at((stop_delay - 5).minutes.from_now, id)
    job_scheduled!(job_name: 'SessionJobs::StopNoStreamSessionJob', job_id: notification_job_id)
  end

  def remove_stop_no_stream_job
    return unless was_job_scheduled?('SessionJobs::StopNoStreamSessionJob')

    SidekiqSystem::Schedule.remove(SessionJobs::StopNoStreamSessionJob, id)
    SidekiqSystem::Schedule.remove(SessionJobs::StopNoStreamSessionNotificationJob, id)
  end

  def job_name_cache_key(job_name, args = {})
    "sessions/#{id}/#{job_name}_#{args}"
  end

  def was_job_scheduled?(job_name, args = {})
    Rails.cache.read(job_name_cache_key(job_name, args)).present?
  end

  def job_scheduled!(job_name:, job_id:, args: {})
    Rails.cache.write(job_name_cache_key(job_name, args), job_id)
  end

  def humanize_type
    if cancelled?
      :cancelled
    elsif finished?
      :past
    else
      :upcoming
    end
  end

  def active?
    return false unless room

    room.actual_start_at < Time.zone.now && Time.zone.now < room.actual_end_at
  end

  def running?
    started? and !finished?
  end

  def cancelled?
    cancelled_at.present?
  end

  def end_at
    return stopped_at if stopped?

    duration.to_i.minutes.since(start_at) if start_at.present?
  end

  # Max: "презентер может нажать позже "start session"
  # хотя это сейчас проблем вроде не вызывает
  # если понадобится реальное время сессии(сколько это длилось) то это будет необходимо"
  def started?
    return false if new_record?

    if start_at_was.present? # because start_at_was used in validations
      start_at_was <= Time.zone.now
    else
      (start_at.present? && start_at <= Time.zone.now)
    end
  end

  def finished?
    return false if new_record?
    return false if start_at.blank?
    return true if stopped?

    Time.zone.now > end_at
  end

  def stopped?
    stopped_at.present?
  end

  def upcoming?
    start_at.present? && Time.zone.now < end_at
  end

  # Return list of times of when we need to remind him
  # on oncoming session
  def remind_about_start_at_times_via_email(user)
    result = [].tap do |result|
      result << 72.hours.until(start_at) if user.receives_reminder?(:hrs_72_via_email)
      result << 24.hours.until(start_at) if user.receives_reminder?(:hrs_24_via_email)
      result << 6.hours.until(start_at) if user.receives_reminder?(:hrs_6_via_email)
      result << 1.hours.until(start_at) if user.receives_reminder?(:hrs_1_via_email)
      result << 15.minutes.until(start_at) if user.receives_reminder?(:mins_15_via_email)
    end

    result.select { |time| time > Time.zone.now }
  end

  # Return list of times of when we need to remind him
  # on oncoming session
  def remind_about_start_at_times_via_web(user)
    result = [].tap do |result|
      result << 72.hours.until(start_at) if user.receives_reminder?(:hrs_72_via_web)
      result << 24.hours.until(start_at) if user.receives_reminder?(:hrs_24_via_web)
      result << 6.hours.until(start_at) if user.receives_reminder?(:hrs_6_via_web)
      result << 1.hours.until(start_at) if user.receives_reminder?(:hrs_1_via_web)
      result << 15.minutes.until(start_at) if user.receives_reminder?(:mins_15_via_web)
    end

    result.select { |time| time > Time.zone.now }
  end

  def remind_about_start_at_times_via_sms(user)
    result = [].tap do |result|
      result << 72.hours.until(start_at) if user.receives_reminder?(:hrs_72_via_sms)
      result << 24.hours.until(start_at) if user.receives_reminder?(:hrs_24_via_sms)
      result << 6.hours.until(start_at) if user.receives_reminder?(:hrs_6_via_sms)
      result << 1.hours.until(start_at) if user.receives_reminder?(:hrs_1_via_sms)
      result << 15.minutes.until(start_at) if user.receives_reminder?(:mins_15_via_sms)
    end

    result.select { |time| time > Time.zone.now }
  end

  def duration_change_times_left_cache_key
    "sessions/#{id}/duration_change_times_left"
  end

  def duration_change_times_left
    return 0 unless persisted? && !finished?

    Rails.cache.fetch(duration_change_times_left_cache_key, expires_at: end_at, raw: true) do
      Rails.application.credentials.global.dig(:sessions, :duration, :change, :times_max)
    end.to_i
  end

  def duration_change_times_left=(value)
    Rails.cache.write(duration_change_times_left_cache_key, value, expires_at: end_at, raw: true)
  end

  def decrement_duration_change_times
    return unless duration_change_times_left.positive?

    Rails.cache.decrement(duration_change_times_left_cache_key)
  end

  def increase_duration(increase_by = nil)
    errors.add(:duration, I18n.t('models.session.errors.duration_change_limit_reached')) and return if duration_change_times_left.zero?

    self.duration += (increase_by || Rails.application.credentials.global.dig(:sessions, :duration, :change, :step_minutes)).to_i
    save!
    decrement_duration_change_times
  end

  def decrease_duration(decrease_by = nil)
    errors.add(:duration, I18n.t('models.session.errors.duration_change_limit_reached')) and return if duration_change_times_left.zero?

    self.duration -= (decrease_by || Rails.application.credentials.global.dig(:sessions, :duration, :change, :step_minutes)).to_i
    save!
    decrement_duration_change_times
  end

  private

  def complies_to_max_book_ahead_system_parameter
    return if errors.include?(:start_at)

    if ::SystemParameter.book_ahead_in_hours_max.hours.from_now < start_at
      errors.add(:start_at,
                 "must not be scheduled ahead for more than #{(::SystemParameter.book_ahead_in_hours_max / 24).to_i} days")
    end
  end

  def not_in_the_past
    return if errors.include?(:start_at)
    return if persisted? && !start_at_changed?

    if start_at < Time.zone.now
      errors.add(:start_at, 'must be in the future time')
    end
  end
end
