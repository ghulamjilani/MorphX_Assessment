# frozen_string_literal: true

class User::BackgroundUploader < Uploader
  process convert: 'jpg'
  process :rotate
  process :cropper
  process resize_to_fill: [1800, 450]
  process :optimize

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end
end
