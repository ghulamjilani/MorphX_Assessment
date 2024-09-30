# frozen_string_literal: true

module LandingHelper
  SIGN_IN_MODAL = 'signin'
  SIGN_UP_MODAL = 'signup'

  def modal_additional_class(type)
    unless [
      ::ProfilesHelper::REPLENISH_MODAL,
      ::LandingHelper::SIGN_IN_MODAL,
      ::LandingHelper::SIGN_UP_MODAL,
      ::DashboardHelper::FACEBOOK_CONTACT_MODAL
    ].include?(type)
      raise ArgumentError
    end

    additional_class = ''
    if session['autodisplay_modal'].present? && session['autodisplay_modal'] == type
      additional_class = 'autodisplay'
      session.delete('autodisplay_modal')
    end
    additional_class += ' signUpWithMedia'
    additional_class
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
