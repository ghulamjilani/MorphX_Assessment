# frozen_string_literal: true

module Api
  module V1
    module User
      class SignupTokensController < Api::V1::ApplicationController
        def create
          @signup_token = SignupToken.usable.find_by!(params.require(:signup_token).permit(:token))
          @signup_token.used_by!(current_user)
          render :show
        end
      end
    end
  end
end
