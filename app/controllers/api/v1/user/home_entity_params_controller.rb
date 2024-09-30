# frozen_string_literal: true

class Api::V1::User::HomeEntityParamsController < Api::V1::User::ApplicationController
  def hide_on_home
    render_json(401, 'You cannot access this action') and return unless current_user.platform_role == 'platform_owner'

    entity_class.find(params[:model_id]).update(hide_on_home: params[:hide_on_home])
    head :ok
  end

  def set_weight
    render_json(401, 'You cannot access this action') and return unless current_user.platform_role == 'platform_owner'

    entity_class.find(params[:model_id]).update(promo_weight: params[:promo_weight])
    head :ok
  end

  private

  def entity_class
    if %w[User Channel Organization Session Video Recording Blog::Post].include?(params[:model_type])
      params[:model_type].constantize
    else
      raise 'Model type is not supported'
    end
  end
end
