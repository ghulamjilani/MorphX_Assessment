# frozen_string_literal: true

class Api::V1::User::ActiveStorage::DirectUploadsController < ActiveStorage::DirectUploadsController
  skip_before_action :verify_authenticity_token
  # TODO: fix MI-6 - auth with jwt
end
