# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_to do |f|
        f.js { render json: {} }
        f.json { render json: {} }
        f.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
      end
    else
      respond_with(resource)
    end
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token_while_skipping_unrelated_validations(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_flashing_format?
      sign_in(resource_name, resource)
      respond_with resource, location: root_path
    else
      flash[:alert] = resource.errors.full_messages.join('. ')
      respond_with resource
    end
  end
end
