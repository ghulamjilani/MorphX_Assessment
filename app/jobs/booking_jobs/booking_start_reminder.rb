# frozen_string_literal: true

class BookingJobs::BookingStartReminder < ApplicationJob
  def perform(id, period)
    booking = ::Booking::Booking.find(id)
    case period
    when '15 minutes'
      BookingMailer.reminder_15_min(id, booking.user.id).deliver_now
      BookingMailer.reminder_15_min(id, booking.booking_slot.user.id).deliver_now
    when '24 hours'
      BookingMailer.reminder_24_hours(id, booking.user.id).deliver_now
      BookingMailer.reminder_24_hours(id, booking.booking_slot.user.id).deliver_now
    end
  rescue StandardError => e
    Airbrake.notify("BookingJobs::BookingStartReminder #{e.message}", parameters: {
                      id: id
                    })
  end
end
