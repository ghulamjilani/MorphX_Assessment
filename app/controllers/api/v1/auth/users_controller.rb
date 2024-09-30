# frozen_string_literal: true

module Api
  module V1
    module Auth
      class UsersController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization, only: [:create]
        before_action :authorization_organization_or_skip, only: [:create]

        def create
          user = ::User.where.not(email: nil).find_by(email: params[:email].to_s.downcase)

          can_connect = if current_organization && user
                          current_organization.user_id == user.id || OrganizationMembership.exists?(user_id: user.id,
                                                                                                    organization_id: current_organization.id)
                        else
                          user&.valid_password?(params[:password])
                        end

          if can_connect
            # set current user for abilities usage
            @auth_user_token = ::Auth::UserToken.create!(user: user, device: request.user_agent, ip: request.remote_ip)
            @current_user = user
            sign_in(:user, @current_user)
            create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: @auth_user_token)
            add_guest_membership(@current_user)

            return render :create
          end

          if current_organization && user
            errors = ActiveModel::Errors.new(::User.new)
            errors.add(:email, 'is invalid for current organization')
          else
            errors = 'email or password is invalid'
          end

          render_json(422, errors)
        end

        def destroy
          sign_out(:user)
          head :ok
        end

        private

        def authorization_organization_or_skip
          authorization if request.headers['Authorization'].present?
        end
      end
    end
  end
end
