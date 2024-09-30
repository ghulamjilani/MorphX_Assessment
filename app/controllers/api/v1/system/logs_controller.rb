# frozen_string_literal: true

class Api::V1::System::LogsController < Api::V1::ApplicationController
  skip_before_action :authorization, if: -> { request.headers['Authorization'].blank? }

  def create
    KafkaLib::Client.send_user(
      request: request, service: params[:service],
      page: params[:page], event_type: params[:event], data: params[:data],
      user_id: current_user&.id
    )
    head :ok
  end
end
