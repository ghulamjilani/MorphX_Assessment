# frozen_string_literal: true

class Api::V1::User::UsersController < Api::V1::User::ApplicationController
  before_action :set_user, only: %i[show update destroy]
  skip_before_action :authorization, :authorization_only_for_user, if: -> { params[:reset_password_token].present? }

  def show
  end

  def update
    @user.attributes = user_attributes

    unless @user.save
      @status = 422
      @user.reload
    end

    render :show, status: (@status || 200)
  end

  def destroy
    render :show
  end

  private

  def set_user
    if params[:reset_password_token].present?
      @current_user = @user = User.reset_password_by_token_while_skipping_unrelated_validations(params.permit(:reset_password_token))
      raise ActiveRecord::RecordNotFound if @current_user.blank?

      @current_ability = nil
    else
      @user = current_user
    end
    @organization = @user.current_organization
    @my_organization = @user.organization
    @organizations = @user.all_organizations
    @has_service_subscription = !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) || @user.service_subscription.present?
    @channel_subscriptions = current_user.channels_subscriptions
    @channel_free_subscriptions = current_user.free_subscriptions.in_action
  end

  def user_attributes
    params.require(:user).permit(
      :birthdate,
      :email,
      :first_name,
      :slug,
      :last_name,
      :display_name,
      :gender,
      :public_display_name_source,
      :time_format,
      :manually_set_timezone,
      :currency,
      :custom_slug,
      :custom_slug_value,
      :password,
      :password_confirmation,
      :language,
      user_account_attributes: %i[bio city country country_state
                                  phone tagline contact_email]
    )
  end
end
