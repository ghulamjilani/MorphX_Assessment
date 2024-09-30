# frozen_string_literal: true

module Api
  module V1
    module User
      class SessionDurationsController < Api::V1::ApplicationController
        before_action :authorization_only_for_user

        def show
          session
          load_variables
        end

        def create
          session.increase_duration(change_by)
          @status = 422 if session.errors.any?
          load_variables
          render :show
        end

        def destroy
          session.decrease_duration(change_by)
          @status = 422 if session.errors.any?
          load_variables
          render :show
        end

        private

        def session
          @session ||= Session.find(params.require(:session_id))
          raise AccessForbiddenError unless can?(:edit, @session)

          @session
        end

        def load_variables
          change_by
          @change_times_left = @session.duration_change_times_left
        end

        def change_by
          @change_by ||= (Rails.application.credentials.global.dig(:sessions, :duration, :change, :step_minutes) || 10).to_i
        end

        def current_ability
          session_ability
        end
      end
    end
  end
end
