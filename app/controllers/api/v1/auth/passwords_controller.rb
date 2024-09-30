# frozen_string_literal: true

module Api
  module V1
    module Auth
      class PasswordsController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization

        def create
          render_json 401 and return if user_params.blank?

          user = ::User.find_by(email: user_params.require(:email).to_s.downcase)
          render_json 404 and return unless user

          user.send_reset_password_instructions
          render_json 200
        end

        private

        def user_params
          params.require(:user).permit(:email)
        end
      end
    end
  end
end
