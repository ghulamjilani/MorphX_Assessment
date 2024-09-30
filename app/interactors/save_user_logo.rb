# frozen_string_literal: true

class SaveUserLogo
  def initialize(user, params)
    @user = user
    @params = params
  end

  def execute
    return false if @params[:logo].blank? || (@params[:logo] && @params[:logo][:original_image].blank?)

    @user.image_attributes = @params[:logo].except(:original_image)
    @user.image.original_image = @params[:logo][:original_image]
    if @user.image.save
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  def logo
    @user.image
  end

  def errors
    @user.image.errors.full_messages.join('. ') unless @user.image.errors.empty?
  end
end
