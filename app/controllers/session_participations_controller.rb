# frozen_string_literal: true

class SessionParticipationsController < ApplicationController
  before_action :authenticate_user!

  def accept_changed_start_at
    sp = SessionParticipation.where(participant: current_user.participant, id: params[:id]).last

    if sp.present? && sp.pending_changed_start_at?
      sp.accept_changed_start_at!
      flash[:success] = I18n.t('controllers.changed_start_at_has_been_accepted_by_user')
    else
      flash[:error] = 'We are sorry but this link is no longer valid.'
    end

    redirect_back fallback_location: dashboard_path
  end

  def decline_changed_start_at
    sp = SessionParticipation.where(participant: current_user.participant, id: params[:id]).last

    if sp.present? && sp.pending_changed_start_at?
      sp.decline_changed_start_at!
      flash[:success] = I18n.t('controllers.changed_start_at_has_been_declined_by_user')
    else
      flash[:error] = 'We are sorry but this link is no longer valid.'
    end

    redirect_back fallback_location: dashboard_path
  end
end
