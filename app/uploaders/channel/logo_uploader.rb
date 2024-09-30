# frozen_string_literal: true

class Channel::LogoUploader < Uploader
  process convert: :jpg
  process :optimize

  def default_url
    ActionController::Base.helpers.asset_path 'gender/newHidden.svg'
  end

  version :small do
    process :rotate
    process :cropper
    process resize_to_fill: [50, 50]
    process :optimize
  end

  version :large do
    process :rotate
    process :cropper
    process resize_to_fill: [200, 200]
    process :optimize
  end
end
