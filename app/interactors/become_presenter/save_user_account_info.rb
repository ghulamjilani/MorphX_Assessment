# frozen_string_literal: true

class BecomePresenter::SaveUserAccountInfo
  def initialize(user, user_account_params)
    @user = user
    @user_account_params = user_account_params
    @logo = @user_account_params.delete('logo')
    @errors = []
  end

  def execute
    @user.build_user_account unless @user.user_account

    @user.user_account_attributes = @user_account_params

    if @logo.present?
      @user.build_image unless @user.image
      @user.image_attributes = @logo
    end

    if @user.save
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  attr_reader :user

  def errors
    @errors << @user.user_account.errors.full_messages if @user.user_account.errors.any?
    @errors << @user.image.errors.full_messages if @user.image&.errors&.any?
    @errors << @user.errors.full_messages if @user.errors.any?
    @errors.flatten.compact.uniq.join('. ')
  end
end
