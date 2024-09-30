# frozen_string_literal: true

class Api::V1::Sandbox::SystemThemesController < Api::V1::ApplicationController
  skip_before_action :authorization
  def index
    render_json(401, 'You cannot access this action') and return unless Rails.env.development?

    @system_themes = SystemTheme.all.preload(:system_theme_variables)
  end
end
