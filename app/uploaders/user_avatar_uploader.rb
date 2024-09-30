# frozen_string_literal: true

class UserAvatarUploader < Uploader
  process :remove_animation
  process convert: 'jpg'
  process :optimize

  def extension_white_list
    carrierwave_extension_white_list + %w[tif tiff gif fcgi]
  end

  def default_url
    gender = model.user&.gender.presence || 'hidden'
    ActionController::Base.helpers.asset_path "gender/#{gender}.png", skip_pipeline: Rails.env.test?
  end

  version :small do
    process :rotate
    process :cropper
    process resize_to_fill: [50, 50]
    process :optimize
  end
  version :medium do
    process :rotate
    process :cropper
    process resize_to_fill: [260, 260]
    process :optimize
  end
  version :large do
    process :rotate
    process :cropper
    process resize_to_fill: [280, 280]
    process :optimize
  end

  private

  def remove_animation
    if content_type == 'image/gif'
      manipulate!(&:collapse!)
    end
  end
end
