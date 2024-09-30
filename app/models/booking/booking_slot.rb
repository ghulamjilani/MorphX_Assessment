# frozen_string_literal: true
class Booking::BookingSlot < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user, class_name: 'User'
  belongs_to :channel, class_name: 'Channel'
  belongs_to :booking_category, class_name: 'Booking::BookingCategory'
  has_many :bookings, class_name: 'Booking::Booking', dependent: :destroy
  has_many :booking_prices, class_name: 'Booking::BookingPrice', dependent: :destroy

  validates :replay_price_cents, numericality: { greater_than_or_equal_to: 99 }, allow_nil: true
  validates :channel_id, :booking_category_id, :name, :slot_rules, :week_rules, presence: true
  accepts_nested_attributes_for :booking_prices

  scope :not_deleted, -> { where(deleted: false) }

  def calculate_price_by_duration(price_id, start_at, end_at)
    # check if week is available
    timezone = user.timezone
    week_number = start_at.in_time_zone(timezone).strftime('%-V').to_i
    raise 'No Slots available' if JSON.parse(week_rules).exclude?(week_number)

    # check if day is available
    rule_day = start_at.in_time_zone(timezone).strftime('%A')
    rule = JSON.parse(slot_rules).detect { |i| i['name'] == rule_day }
    raise 'No Slots available' if rule['scheduler'].blank?

    # check if time range is available
    available_range = nil
    start_at = start_at.in_time_zone(timezone)
    end_at = end_at.in_time_zone(timezone)
    rule['scheduler'].each do |date_range|
      rule_start = DateTime.new(start_at.year, start_at.month, start_at.day, date_range['start'].split(':').first.to_i, date_range['start'].split(':').last.to_i, 0, start_at.strftime('%:z'))
      rule_end = DateTime.new(end_at.year, end_at.month, end_at.day, date_range['end'].split(':').first.to_i, date_range['end'].split(':').last.to_i, 0, end_at.strftime('%:z'))
      if start_at >= rule_start && start_at < rule_end && end_at <= rule_end
        available_range = date_range
        break
      end
    end

    # check if price is available for this duration
    available_price = booking_prices.find(price_id)

    # finally calculate
    if available_range.present? && available_price.present?
      multiplier = available_range['multiplier'].present? && !available_range['multiplier'].zero? ? available_range['multiplier'].to_f / 100 : 0
      (available_price.price_cents + (available_price.price_cents * multiplier)).round.to_i
    else
      raise 'No Slots available'
    end
  end
end
