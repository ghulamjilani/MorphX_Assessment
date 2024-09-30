# frozen_string_literal: true

class WizardV2::SummaryController < WizardV2::ApplicationController
  before_action :authenticate_user!
  skip_before_action :check_if_completed_creator
  skip_before_action :check_if_can_use_wizard

  def show
    current_user.presenter.update!({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::DONE })
  end

  def submit_for_approval
    channel = current_user.channels.order(created_at: :desc).first
    if params[:list_upon_approval]
      channel.update_attribute(:list_automatically_after_approved_by_admin, true)
    end
    channel.submit_for_review! if channel.draft?
    current_user.presenter.update_attribute(:last_seen_become_presenter_step, nil)
    current_user.touch
    redirect_to channel.relative_path
  end
end
