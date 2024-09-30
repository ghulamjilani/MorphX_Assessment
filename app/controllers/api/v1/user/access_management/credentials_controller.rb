# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class CredentialsController < Api::V1::User::AccessManagement::ApplicationController
          def index
            # authorize!(:manage_roles, current_user.current_organization)
            @credentials = ::AccessManagement::Credential.active.order(
              access_management_category_id: :asc, code: :asc
            )
            @count = @credentials.count
          end
        end
      end
    end
  end
end
