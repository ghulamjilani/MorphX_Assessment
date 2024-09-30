# frozen_string_literal: true

module Api
  module V1
    module Auth
      class OrganizationsController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization, only: [:create]

        def create
          @organization = ::Organization.where.not(secret_key: nil).find_by(secret_key: params[:secret_key])
          if @organization&.token_is_correct?(params[:secret_token])
            create_jwt_properties(type: ::Auth::Jwt::Types::ORGANIZATION, model: @organization)
            render :create
          else
            render_json 401
          end
        end
      end
    end
  end
end
