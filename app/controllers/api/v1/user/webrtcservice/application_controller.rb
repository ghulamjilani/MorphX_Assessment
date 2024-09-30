# frozen_string_literal: true

class Api::V1::User::Webrtcservice::ApplicationController < Api::V1::User::ApplicationController
  before_action :authorization_only_for_user
end
