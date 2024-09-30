# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ControllerConcerns::RedirectUtils
  include ControllerConcerns::Api::V1::CookieAuth

  def new
    session['autodisplay_modal'] = LandingHelper::SIGN_IN_MODAL
    redirect_to root_path
  end

  # POST /resource/sign_in
  def create
    Rails.logger.info "tokenIssue - #{params.inspect}"
    self.resource = warden.authenticate!(auth_options)
    # set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    if params.has_key?(:embed)
      render json: { user: resource&.as_json(only: :id) }
      return
    end
    @after_sign_in_path = after_sign_in_path_for(resource)

    respond_to do |format|
      format.html do
        respond_with resource, location: @after_sign_in_path
      end
      format.json
      format.js
    end
  end

  # DELETE /resource/sign_out
  def destroy
    cookies.delete(:force_go_live_form)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    # set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?
    if request.format.json?
      reset_session
    end
    respond_to_on_destroy
  end
end
