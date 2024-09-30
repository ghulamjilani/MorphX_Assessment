# frozen_string_literal: true

class Api::V1::Blog::ApplicationController < Api::V1::ApplicationController
  skip_before_action :authorization, unless: -> { request.headers['Authorization'].present? }
  before_action :authorization_only_for_user
end
