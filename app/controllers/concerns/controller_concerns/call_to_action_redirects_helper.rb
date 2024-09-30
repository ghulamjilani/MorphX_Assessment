# frozen_string_literal: true

module ControllerConcerns::CallToActionRedirectsHelper
  extend ActiveSupport::Concern

  def check_return_to
    if (return_to = session['return_to'])
      Rails.logger.info logger_user_tag + "return_to is present: #{return_to}"
      session.delete('return_to')
      redirect_to(return_to)
    end
  end

  def expect_user_to_be_confirmed
    unless current_user.confirmed?
      flash[:error] = 'You have to confirm your email address before continuing.'
    end
  end

  private

  def current_action_requires_completed_profile_data?
    !is_a?(BecomePresenterStepsController) &&
      !is_a?(::Devise::SessionsController) &&
      !is_a?(::Users::OmniauthCallbacksController)
  end
end
