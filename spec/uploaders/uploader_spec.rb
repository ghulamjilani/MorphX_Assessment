# frozen_string_literal: true

require 'spec_helper'

describe 'Uploader' do
  describe '#croppper' do
    it 'does not raise when nan crop size' do
      model = create(:user_image, crop_x: 'NaN')
      u = Uploader.new(model, :original_image)
      u.store!(File.open(ImageSample.for_size('280x280')))
      expect { u.cropper }.not_to raise_error
    end
  end
end
