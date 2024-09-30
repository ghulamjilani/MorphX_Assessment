# frozen_string_literal: true

class Api::V1::Organization::ApplicationController < Api::V1::ApplicationController
  before_action :authorization_only_for_organization
end
