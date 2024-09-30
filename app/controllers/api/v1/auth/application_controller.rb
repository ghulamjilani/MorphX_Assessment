# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ApplicationController < Api::V1::ApplicationController
        include ControllerConcerns::Api::V1::Auth::RefOrganization
      end
    end
  end
end
