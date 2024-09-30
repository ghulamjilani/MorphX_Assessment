# frozen_string_literal: true
class Booking::BookingCategory < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
end
