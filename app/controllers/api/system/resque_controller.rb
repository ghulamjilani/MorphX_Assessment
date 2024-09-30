# frozen_string_literal: true

class Api::System::ResqueController < Api::System::ApplicationController
  before_action :http_basic_authenticate

  def create_reminders
    obj.create_reminders
    head 200
  end

  def disable_reminders
    obj.disable_reminders
    head 200
  end

  private

  def obj
    @obj ||= if %w[SessionInvitedImmersiveCoPresentership SessionInvitedImmersiveParticipantship
                   SessionInvitedLivestreamParticipantship].include? params[:model]
               params[:model].constantize.find(params[:model_id])
             else
               raise 'unknown model'
             end
  end
end
