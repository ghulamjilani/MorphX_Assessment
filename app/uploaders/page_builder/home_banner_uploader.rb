# frozen_string_literal: true

class PageBuilder::HomeBannerUploader < Uploader
  process convert: :jpg
  process :optimize

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end

  version :main do
    process :rotate
    process :cropper
    process resize_to_fill: [1980, 510] # резерв 1530 x 400, на случай если прийдется уменьшать из за конского веса, что бы не потерять сразу укажу
    process :optimize
  end
end
