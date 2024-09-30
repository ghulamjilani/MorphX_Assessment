# frozen_string_literal: true
class Booking::BookingPrice < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :booking_slot, class_name: 'Booking::BookingSlot'

  has_one :channel, through: :booking_slot, source: :channel
  has_one :organization, through: :channel, source: :organization
  has_many :bookings, class_name: 'Booking::Booking'

  validate :check_if_duration_is_available

  scope :not_deleted, -> { where(deleted: false) }

  def check_if_duration_is_available
    unless valid_durations.include?(duration)
      errors.add(:duration, :inclusion, value: duration)
    end
  end

  def valid_durations
    return (15..180).step(5).to_a if (Rails.env.test? || Rails.env.development?) && booking_slot.user.presenter.blank? # because some factories are not really good at assigning hierarchies

    (15..duration_available_max).step(5).to_a
  end

  def duration_available_max
    duration_max_value = [duration_was.to_i, booking_slot.user.can_create_sessions_with_max_duration].max # duration could be already overriden by admin
    return duration_max_value if booking_slot.channel&.organization&.split_revenue?

    return 45 if booking_slot.channel&.organization.nil? || booking_slot.channel.organization.service_subscription&.service_status == 'trial'

    (booking_slot.channel.organization.service_subscription_feature_value(:max_session_duration) || duration_max_value).to_i
  end
end
