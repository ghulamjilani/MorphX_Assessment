# frozen_string_literal: true

class BookingJobs::CreateSession < ApplicationJob
  def perform(id)
    booking = Booking::Booking.find(id)
    return if booking.session.present?

    replay_price = booking.booking_slot.replay? ? booking.booking_slot.replay_price_cents.to_i / 100.0 : nil
    user = booking.booking_slot.user
    user.create_presenter if user.presenter.blank?
    session = booking.create_session!(
      channel: booking.booking_slot.channel,
      adult: false,
      allow_chat: true,
      autostart: true,
      duration: booking.duration,
      immersive_free: true,
      immersive_purchase_price: 0,
      immersive_type: Session::ImmersiveTypes::ONE_ON_ONE,
      level: 'All Levels',
      max_number_of_immersive_participants: 1,
      private: true,
      recorded_free: replay_price.nil? ? false : replay_price.zero?,
      recorded_purchase_price: replay_price,
      start_at: booking.start_at,
      title: "#{user.public_display_name} session with #{booking.user.public_display_name}",
      presenter_id: user.presenter.id,
      status: ::Session::Statuses::PUBLISHED
    )
    booking.user.create_participant! if booking.user.participant.blank?
    session.session_invited_immersive_participantships.create!(participant: booking.user.participant, session: session, status: :accepted)
    session.session_participations.create!(participant: booking.user.participant, session: session, status: :confirmed)
    booking.user.follow(booking.booking_slot.user) unless booking.user.following?(booking.booking_slot.user)
    BookingMailer.owner_has_new_booking(booking.id).deliver_now
    BookingMailer.user_has_new_booking(booking.id).deliver_now
  rescue StandardError => e
    puts e
    Airbrake.notify("BookingJobs::CreateSession #{e.message}", parameters: {
                      id: id
                    })
  end
end
