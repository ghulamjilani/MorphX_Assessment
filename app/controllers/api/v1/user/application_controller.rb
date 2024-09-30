# frozen_string_literal: true

module Api
  module V1
    module User
      class ApplicationController < Api::V1::ApplicationController
        before_action :authorization_only_for_user

        def own_organization
          @own_organization ||= current_user.organization
        end
        helper_method :own_organization

        def authorization_for_own_organization
          render_json 401, 'Only organization can get access here' if own_organization.blank?
        end
      end
    end
  end
end
