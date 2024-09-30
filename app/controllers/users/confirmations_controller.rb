# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :html, :json

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.present?
      Airbrake.notify('Users::ConfirmationsController#show: confirmation failed', parameters: params,
                                                                                  errors: resource.errors)
      return redirect_to(root_path, flash: { error: resource.errors.full_messages.join('. ') })
    end

    set_flash_message(:notice, :confirmed) if is_flashing_format?
    sign_in(resource) # <= THIS LINE ADDED see http://stackoverflow.com/a/20961042 to know why
    respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(_resource_name)
    root_path if is_navigational_format?
  end

  # The path used after confirmation.
  def after_confirmation_path_for(_resource_name, resource)
    return root_path if resource.has_owned_channels? # no need to redirect to "Become a presenter" if he is already one

    # it is not permanent but acceptable, no one remember what he did on any website 1 month ago
    if (return_to = Rails.cache.read("after_confirmation_path_for/#{resource.id}"))
      return_to
    else
      root_path
    end
  end
end
