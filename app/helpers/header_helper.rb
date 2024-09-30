# frozen_string_literal: true

module HeaderHelper
  def display_signup?
    # Don't show on landing by default or if turned off and no token
    return false if (params[:controller] == 'home' && params[:action] == 'landing') && (!Rails.application.credentials.frontend[:landing_sign_up] && params[:token].blank?)
    # Don't show if turned off global and no token
    return false unless Rails.application.credentials.global[:sign_up][:enabled]
    # Don't show on wizard
    return false if params[:controller] == 'wizard'

    true
  end
end
