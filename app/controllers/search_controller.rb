# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :set_current_organization

  layout 'application'

  def show
    return redirect_to root_path if Rails.application.credentials.global[:enterprise]
  end

  private

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end
end
