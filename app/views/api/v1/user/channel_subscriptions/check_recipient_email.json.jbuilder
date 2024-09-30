# frozen_string_literal: true

envelope json do
  json.email    @user&.email
  json.name     @user&.persisted? ? @user.public_display_name : 'New User'
  json.is_valid @is_valid
  json.message  @message
end
