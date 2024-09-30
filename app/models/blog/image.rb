# frozen_string_literal: true
class Blog::Image < Blog::ApplicationRecord
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :blog_post, class_name: 'Blog::Post', touch: true
  belongs_to :organization, required: true

  validates :image, presence: true
  validate :image_filesize_validity, if: :image?, on: :create

  alias_attribute :carrierwave_id, :id
  mount_uploader :image, Blog::Post::ImageUploader

  scope :attached, -> { where.not(blog_post_id: nil) }
  scope :not_attached, -> { where(blog_post_id: nil) }

  def large_url
    image.large.url
  end

  private

  def image_filesize_validity
    if image.file.size.to_f > 20.megabytes.to_f
      errors.add(:image, "Image #{image.file.original_filename} should be a maximum size of 20Mb")
      return
    end

    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if image.path.nil?

    begin
      magick_image = MiniMagick::Image.open(image.path)
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end
end
