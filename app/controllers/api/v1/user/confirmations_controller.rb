# frozen_string_literal: true

class Api::V1::User::ConfirmationsController < Api::V1::ApplicationController
  def create
    user = current_user

    result = user.send(:pending_any_confirmation) do
      user.send_confirmation_instructions
    end.present?
    status = result ? 201 : 401
    @error = user.pretty_errors if user.errors.present?
    render_json(status, { result: result, error: @error }) and return
  end
end
