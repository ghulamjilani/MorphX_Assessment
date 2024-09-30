# frozen_string_literal: true

class BookingMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def owner_has_new_booking(id)
    @booking = ::Booking::Booking.find(id)

    @subject = 'Your Session Booking Confirmation and Exciting News!'

    ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @booking.booking_slot.user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail(to: @booking.booking_slot.user.email, subject: @subject)
  end

  def user_has_new_booking(id)
    @booking = ::Booking::Booking.find(id)

    @subject = 'Your Session Booking Confirmation and Exciting News!'

    ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @booking.user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail(to: @booking.user.email, subject: @subject)
  end

  def reminder_15_min(id, user_id)
    @booking = ::Booking::Booking.find(id)
    @user = ::User.find(user_id)

    @subject = 'Get Ready to Join Your Session - Only 15 Minutes Left!'

    ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail(to: @user.email, subject: @subject)
  end

  def reminder_24_hours(id, user_id)
    @booking = ::Booking::Booking.find(id)
    @user = ::User.find(user_id)

    @subject = 'Reminder: Your Upcoming Session is Just 24 Hours Away!'

    ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail(to: @user.email, subject: @subject)
  end
end
