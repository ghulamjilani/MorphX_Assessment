# frozen_string_literal: true

class Api::V1::System::CableController < Api::System::ApplicationController
  before_action :http_basic_authenticate

  def create
    raise 'channel missing' if params[:channel].blank?

    channel = params[:channel].camelize.constantize
    raise 'event is missing' if params[:event].blank?

    event = params[:event]
    data = JSON.parse(params[:data])

    if params[:to_object].present? && (to_object = JSON.parse(params[:to_object]))
      object = to_object['class'].constantize.find to_object['id']
      channel.broadcast_to object, event: event, data: data
    else
      channel.broadcast event, data
    end

    head :ok
  rescue StandardError => e
    render json: { message: e.message }, status: 422
  end
end
