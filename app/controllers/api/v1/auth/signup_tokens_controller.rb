# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SignupTokensController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization

        def show
          @signup_token = SignupToken.usable.find_by!(token: params[:id])
        end
      end
    end
  end
end
