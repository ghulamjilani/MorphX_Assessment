# frozen_string_literal: true

module Api
  module V1
    module Auth
      class WebsocketTokensController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization, if: -> { request.headers['Authorization'].blank? }

        def create
          @auth_websocket_token = ::Auth::WebsocketToken.create(abstract_user: current_user_or_guest, visitor_id: params.require(:visitor_id))
        end
      end
    end
  end
end
