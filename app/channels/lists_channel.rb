# frozen_string_literal: true

class ListsChannel < ApplicationCable::Channel
  EVENTS = {
    product_added: 'New product added to list. Data: { product_id: product_id, list_id: list_id }'
  }.freeze

  def subscribed
    stream_from 'lists_channel'

    if (list = List.find_by(id: params[:data]))
      stream_for list
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
