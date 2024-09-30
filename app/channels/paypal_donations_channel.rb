# frozen_string_literal: true

class PaypalDonationsChannel < ApplicationCable::Channel
  EVENTS = {
    made: 'New paypal donation made for session. Data: {abstract_session_type: pd.abstract_session.class.to_s, abstract_session_id: pd.abstract_session.id}'
  }.freeze

  def subscribed
    if (session = Session.find_by(id: params[:data]))
      stream_for session
    end
  end

  def unsubscribed
    stop_stream_from 'paypal_donations_channel'
    # Any cleanup needed when channel is unsubscribed
  end
end
