# frozen_string_literal: true

module Api
  module V1
    module User
      module Booking
        class BookingCategoriesController < Api::V1::User::Booking::ApplicationController
          def index
            @booking_categories = ::Booking::BookingCategory.all
          end
        end
      end
    end
  end
end
