# frozen_string_literal: true

module Api
  module V1
    module Webhook
      module Partner
        class ApplicationController < ::Api::V1::Webhook::ApplicationController
          def authorization_only_for_organization
            render_json 401, 'Only organization can get access here' if current_organization.blank?
          end
        end
      end
    end
  end
end
