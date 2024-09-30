# frozen_string_literal: true

class Api::System::MailersController < Api::System::ApplicationController
  before_action :http_basic_authenticate

  def local_request?
    !Rails.env.production?
  end

  def you_as_co_presenter_accepted_session_invitation
    SessionMailer.you_as_co_presenter_accepted_session_invitation(params[:session_id], params[:user_id]).deliver_later
    head :ok
  end

  def user_rejected_your_session_invitation
    Immerss::SessionMultiFormatMailer.new.user_rejected_your_session_invitation(params[:session_id],
                                                                                params[:user_id]).deliver
    head :ok
  end

  def user_accepted_your_session_invitation
    Immerss::SessionMultiFormatMailer.new.user_accepted_your_session_invitation(params[:session_id],
                                                                                params[:user_id]).deliver
    head :ok
  end
end
