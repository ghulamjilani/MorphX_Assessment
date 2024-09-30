# frozen_string_literal: true

class Dashboard::StatisticsController < Dashboard::ApplicationController
  def index
    redirect_to dashboard_path and return if Rails.env.production?
  end
end
