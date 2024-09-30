# frozen_string_literal: true

class Api::V1::Public::ApplicationController < Api::V1::ApplicationController
  skip_before_action :authorization, unless: -> { request.headers['Authorization'].present? }
end
