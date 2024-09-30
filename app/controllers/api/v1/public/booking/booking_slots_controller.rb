# frozen_string_literal: true

module Api
  module V1
    module Public
      module Booking
        class BookingSlotsController < Api::V1::Public::Booking::ApplicationController
          def index
            @booking_slots = ::User.find(params[:user_id]).booking_slots
          end
        end
      end
    end
  end
end
