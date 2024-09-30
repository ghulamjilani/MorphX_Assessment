# frozen_string_literal: true

class Uploader < CarrierWave::Uploader::Base
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  # include ::CarrierWave::Backgrounder::Delay

  def extension_white_list
    carrierwave_extension_white_list
  end

  def filename
    if original_filename.present?
      if versions.empty? && model.try(:main_filename)
        model.main_filename
      else
        "#{md5_filename}.jpg"
      end
    end
  end

  if Rails.env.qa? || Rails.env.production?
    def store_dir
      "#{model.class.to_s.underscore}/#{model.carrierwave_id}/#{mounted_as}"
    end
  elsif Rails.env.development? || Rails.env.test?
    def store_dir
      "uploads/#{Rails.env}/#{model.class.to_s.underscore}/#{model.carrierwave_id}/#{mounted_as}"
    end
  end

  if Rails.env.qa? || Rails.env.production?
    self.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV['S3_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      region: 'us-west-2'
    }
    self.fog_directory = ENV['S3_BUCKET']
    self.fog_attributes = { 'Cache-Control' => 'max-age=315576000' }

    storage :fog
  elsif Rails.env.test? || Rails.env.development?
    storage :file
  end

  def cropper
    return unless model.cropping?
    return if model.crop_w.nan? || model.crop_h.nan? || model.crop_x.nan? || model.crop_y.nan? # I can't reproduce this, but we have AR error

    manipulate! do |img|
      crop_w = model.crop_w.to_i
      crop_h = model.crop_h.to_i
      crop_x = model.crop_x.to_i
      crop_y = model.crop_y.to_i
      crop_params = "#{crop_w}x#{crop_h}#{(crop_x >= 0) ? '+' : ''}#{crop_x}#{(crop_y >= 0) ? '+' : ''}#{crop_y}!"
      img.combine_options do |combined|
        combined.crop(crop_params)
        combined.background('#F2F2F2')
        combined.flatten if crop_x.negative? || crop_y.negative?
      end
      img
    end
  end

  def rotate
    if model.rotate.present?
      manipulate! do |img|
        img.rotate model.rotate.to_i
        img
      end
    end
  end

  def optimize
    manipulate! do |img|
      img.strip
      img.combine_options do |c|
        c.quality 80
        c.depth 8
        c.interlace 'Line'
      end
      img
    end
  end

  private

  def md5_filename
    @md5_filename ||= "#{md5}_#{cache_id}"
  end

  def md5
    @md5 ||= Digest::MD5.hexdigest(model.send(mounted_as).read.to_s)
  end
end
