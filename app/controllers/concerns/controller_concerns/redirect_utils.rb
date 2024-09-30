# frozen_string_literal: true

module ControllerConcerns::RedirectUtils
  extend ActiveSupport::Concern

  included do
    before_action :store_current_location, if: :should_store_location?
  end

  # https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in
  # NOTE: do not remove this method of admins won't be able to access /admin after signing in
  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.is_a?(Admin)
      service_admin_panel_root_path
    elsif request.referer == root_url
      dashboard_path
    else
      redirect_back_to_after_signup = cookies['redirect_back_to_after_signup']
      cookies.delete :redirect_back_to_after_signup

      redirect_back_to_after_signup || params[:redirect_to] || request.referer ||
        stored_location_for(resource_or_scope) || signed_in_root_path(resource_or_scope)
    end
  end

  # override the devise helper to store the current location so we can
  # redirect to it after loggin in or out. This override makes signing in
  # and signing up work automatically.
  def store_current_location
    store_location_for(:user, request.url)
  end

  def should_store_location?
    request.format.html? && !devise_controller? && !current_user && !dashboard_controller?
  end

  def devise_controller?
    !params[:controller] || params[:controller]&.start_with?('users/')
  end

  def dashboard_controller?
    !params[:controller] || params[:controller]&.start_with?('dashboard')
  end
end
