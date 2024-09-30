# frozen_string_literal: true

module Api
  module V1
    module User
      module Payouts
        class StatesController < Api::V1::User::ApplicationController
          def index
            @states = ::Payouts::Countries::STATES[params.require(:country_code).upcase.to_sym]
          end
        end
      end
    end
  end
end
