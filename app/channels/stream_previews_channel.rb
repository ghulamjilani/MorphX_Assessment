# frozen_string_literal: true

class StreamPreviewsChannel < ApplicationCable::Channel
  EVENTS = {
    stream_status: 'Notifies about stream preview status while stream preview is active and on preview stop. Data: {stream_status: wa.stream_status}'
  }.freeze

  def subscribed
    stream_from 'stream_previews_channel'

    wa = FfmpegserviceAccount.find_by(id: params[:data])

    stream_for(wa) if wa.present?
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
