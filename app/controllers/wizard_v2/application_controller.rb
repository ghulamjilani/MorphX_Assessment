# frozen_string_literal: true

class WizardV2::ApplicationController < ApplicationController
  before_action :check_if_completed_creator
  # before_action :check_is_wizard_enabled
  before_action :check_if_can_use_wizard

  private

  def check_if_completed_creator
    unless current_user && current_user.owned_channels.approved.count.zero?
      respond_to do |format|
        format.html do
          redirect_to dashboard_path
        end
        format.json { render json: { message: I18n.t('controllers.wizard_v2.application_controller.already_creator', creator: I18n.t('dictionary.creator')) }, status: 422 }
      end
    end
  end

  def check_is_wizard_enabled
    return redirect_to root_path unless Rails.application.credentials.global.dig(:wizard, :enabled)
  end

  def check_if_can_use_wizard
    return redirect_to root_path unless current_user.can_use_wizard?
  end
end
