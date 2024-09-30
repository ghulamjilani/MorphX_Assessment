# frozen_string_literal: true

class SaveUserCover
  def initialize(user, params)
    @user = user
    @user_account = @user.user_account || user.build_user_account
    @params = params
  end

  def execute
    return false if @params[:original_bg_image].blank?

    @user_account.attributes = @params.permit(:original_bg_image, :crop_x, :crop_y, :crop_w, :crop_h, :rotate)
    @user_account.valid?
    if @user_account.errors[:cover].empty?
      @user_account.save(validate: false)
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  attr_reader :user_account

  def errors
    @user_account.errors[:cover].join('. ') unless @user_account.errors[:cover].empty?
  end
end
