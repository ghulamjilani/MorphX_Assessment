# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class ApplicationController < Api::V1::User::ApplicationController
          def current_user
            # TODO: refactor me. API should be able to work on the organization's token. Temporary solution for the GB API
            super || current_organization&.user
          end
        end
      end
    end
  end
end
