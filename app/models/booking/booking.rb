# frozen_string_literal: true
class Booking::Booking < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :booking_slot
  belongs_to :booking_price
  belongs_to :session
  belongs_to :payment_transaction

  has_one :channel, through: :booking_slot, source: :channel

  validates :start_at, :end_at, :booking_slot_id, :booking_price_id, :user_id, :duration, presence: true
  validate :not_in_the_past
  validate :validate_available_time
  validate :validate_booked_time

  enum status: { pending: 0, approved: 1, rejected: 2 }

  after_commit :create_booked_session, on: :create
  after_commit :setup_notifications, on: :create

  private

  def validate_available_time
    timezone = booking_slot.user.timezone
    week_number = start_at.in_time_zone(timezone).strftime('%-V').to_i
    if JSON.parse(booking_slot.week_rules).exclude?(week_number)
      errors.add(:slot_time, 'not available')
      return
    end

    rule_day = start_at.in_time_zone(timezone).strftime('%A')
    rule = JSON.parse(booking_slot.slot_rules).detect { |i| i['name'] == rule_day }
    if rule.nil? || rule['scheduler'].blank?
      errors.add(:slot_time, 'not available')
      return
    end

    available_range = nil
    tz_start_at = start_at.in_time_zone(timezone)
    tz_end_at = end_at.in_time_zone(timezone)
    rule['scheduler'].each do |date_range|
      rule_start = DateTime.new(tz_start_at.year, tz_start_at.month, tz_start_at.day, date_range['start'].split(':').first.to_i, date_range['start'].split(':').last.to_i, 0, tz_start_at.strftime('%:z'))
      rule_end = DateTime.new(tz_end_at.year, tz_end_at.month, tz_end_at.day, date_range['end'].split(':').first.to_i, date_range['end'].split(':').last.to_i, 0, tz_end_at.strftime('%:z'))
      if tz_start_at >= rule_start && tz_start_at < rule_end && tz_end_at <= rule_end
        available_range = date_range
        break
      end
    end
    unless available_range
      errors.add(:slot_time, 'not available')
    end
  end

  def validate_booked_time
    if ::Booking::Booking.joins(:booking_slot).where(%{booking_slots.user_id = :user_id AND bookings.id != :id AND ((bookings.start_at::timestamp, bookings.end_at::timestamp) overlaps (:start_at::timestamp, :end_at::timestamp))},
                                                     user_id: booking_slot.user_id, id: id || -1, start_at: start_at.utc, end_at: end_at.utc).present?
      errors.add(:slot_time, 'already booked')
    end
  end

  def create_booked_session
    ::BookingJobs::CreateSession.perform_async(id)
  end

  def setup_notifications
    { '15 minutes': 15.minutes.until(start_at), '24 hours': 24.hours.until(start_at) }.each_pair do |period, time|
      ::BookingJobs::BookingStartReminder.perform_at(time, id, period) if time > Time.now
    end
  end

  def not_in_the_past
    return if errors.include?(:start_at)
    return if persisted? && !saved_change_to_start_at?

    if start_at < Time.zone.now
      errors.add(:start_at, 'must be in the future time')
    end
  end
end
