# frozen_string_literal: true

module Api
  module V1
    module User
      module Payouts
        class CountriesController < Api::V1::User::ApplicationController
          def index
            @countries = ::Payouts::Countries::ALL
          end
        end
      end
    end
  end
end
