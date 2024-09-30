# frozen_string_literal: true

class Dashboard::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_organization

  protected

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end
end
