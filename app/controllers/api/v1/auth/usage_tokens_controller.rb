# frozen_string_literal: true

module Api
  module V1
    module Auth
      # To generate refresh token
      class UsageTokensController < Api::V1::Auth::ApplicationController
        include ControllerConcerns::Shared::Authentication

        before_action :authorization, if: -> { request.headers['Authorization'].present? }

        def create
          visitor_id = params[:visitor_id] || cookies.permanent[:visitor_id]
          render_json(422, 'visitor_id is missing') and return if visitor_id.blank?

          encoder = ::Auth::Jwt::Encoder.new(type: ::Auth::Jwt::Types::USAGE, model: current_user, options: { visitor_id: visitor_id })
          @usage_jwt_exp = encoder.expires_at
          @usage_jwt = encoder.jwt
          @usage_user_messages_url = ::Usage.config[:user_messages_url]
          render_json(503, 'visitor_id is missing') and return if @usage_jwt.blank? || @usage_user_messages_url.blank?
        end
      end
    end
  end
end
