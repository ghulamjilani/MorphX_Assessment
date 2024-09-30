# frozen_string_literal: true

class Api::V1::User::SystemThemesController < Api::V1::User::ApplicationController
  def index
    render_json(401, 'You cannot access this action') and return unless current_user.can_use_debug_area?

    @themes = SystemTheme.limit(@limit).offset(@offset)
  end

  def show
    render_json(401, 'You cannot access this action') and return unless current_user.can_use_debug_area?

    @theme = SystemTheme.includes(:system_theme_variables).find(params[:id])
  end

  def update
    render_json(401, 'You cannot access this action') and return unless current_user.can_use_debug_area?

    @theme = SystemTheme.find(params[:id])
    @theme.update(theme_attributes)
    render :show
  end

  private

  def theme_attributes
    params.require(:theme).permit(
      :name,
      :custom_styles,
      :is_default,
      system_theme_variables_attributes:
          %i[id
             name
             property
             value
             state
             group_name
             _destroy]
    )
  end
end
