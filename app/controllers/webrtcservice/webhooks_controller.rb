# frozen_string_literal: true

module Webrtcservice
  class WebhooksController < ActionController::Base
    protect_from_forgery only: []
    before_action :validate_token

    def create
      ImWebrtcservice::Events.handle(params: message_params)
      render json: {}
    end

    private

    def message_params
      params.permit(:ChannelSid, :EventType, :MessageSid)
    end

    def validate_token
      token = params.permit(:token)[:token]
      # This param must be placed in webhook url. This ensures that request came from webrtcservice
      unless token == ENV['webrtcservice_WEBHOOK_TOKEN']
        head :bad_request
      end
    end
  end
end
