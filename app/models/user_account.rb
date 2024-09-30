# frozen_string_literal: true
class UserAccount < ActiveRecord::Base
  # fixes #1012
  # talent_list, tagline, bio
  attr_accessor :validate_public_info

  # it is forced only when user uploads it manually
  # we don't force validation in case of pulling default avatars from Facebook/LinkedIn
  attr_accessor :force_image_validation

  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::HasPostgresLoImage
  include ModelConcerns::CanWrapExternalUrls
  include ModelConcerns::ActiveModel::Extensions

  wrap_external_urls :bio

  acts_as_ordered_taggable_on :talents

  mount_uploader :original_bg_image, Uploader
  mount_uploader :bg_image,          User::BackgroundUploader, validate_integrity: true, validate_processing: true
  alias_attribute :carrierwave_id, :user_id
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :rotate

  belongs_to :user, touch: true, inverse_of: :user_account
  belongs_to :found_us_method

  has_many :social_links, as: :entity, dependent: :destroy

  before_validation :sanitize_bio
  before_validation :sanitize_phone

  # state is currently not used because AVS does not need it
  # validates :country_state, length: { maximum: 160 }, presence: true, if: ->(ua) { ua.validate_fields? && ua.us_country? }

  validates :country, inclusion: ISO3166::Country.codes, allow_nil: false, if: ->(ua) { ua.validate_fields? }
  validates :user, presence: true, uniqueness: true

  validates :talent_list, length: {
    minimum: 0,
    too_short: 'must have at least %{count} tags',
    too_long: 'must have at most %{count} tags',
    maximum: 20
  }
  validates :bio, presence: true, if: ->(ua) { ua.user.presenter && ua.validate_public_info }
  validates :tagline, length: { maximum: 160, minimum: 8 }, allow_blank: true
  validate  :bio_text_length, if: ->(ua) { ua.validate_public_info }

  validate :cover_dimensions_and_size_validity, if: :original_bg_image_changed?
  after_validation :set_versions, if: ->(o) { o.original_bg_image_changed? && o.errors.empty? }

  phony_normalize :phone

  after_commit :user_reindex, if: ->(acc) { acc.saved_change_to_tagline? or acc.saved_change_to_bio? }, on: :update
  after_commit :user_reindex, on: :create

  accepts_nested_attributes_for :social_links, reject_if: proc { |attributes|
                                                            attributes['link'].blank? and attributes['id'].blank?
                                                          }, allow_destroy: true

  def us_country?
    country.to_s == 'US'
  end

  def validate_fields?
    [
      country_state,
      country,
      phone
    ].any? { |attr| !attr.nil? }
  end

  def object_label
    "User Account of #{user.object_label}"
  end

  # # this is monkey-patching of carrierwave so that it does not assign artificial id(oid) with zero file length
  # # when no image is assigned to :bg_image
  # # see https://github.com/carrierwaveuploader/carrierwave/blob/aadbe94a525d3b685623cd5141da1c99de5eb972/lib/carrierwave/orm/activerecord.rb#L57-L58
  # def write_original_bg_image_identifier
  #   return unless original_bg_image.present?
  #
  #   super
  # end

  # def remove_image!
  #   try_remove_image :original_bg_image
  # end

  # NOTE: used by Authy
  # @return [String] for example '971126326'
  def cellphone
    return nil if phone.blank?

    normalized   = Phony.normalize(phone)
    splitted     = Phony.split(normalized)
    #=> "683728661"
    cellphone    = splitted[1..].join('')
  end

  # NOTE: used by Authy
  # @return [String] for example '380'
  def country_code
    return nil if phone.blank?

    normalized   = Phony.normalize(phone)
    splitted     = Phony.split(normalized)
    #=> "380"
    country_code = splitted.first
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def bg_image_url
    ActionController::Base.helpers.asset_path(super)
  end

  def main_filename
    attributes['bg_image']
  end

  private

  def cover_dimensions_and_size_validity
    unless original_bg_image.file
      errors.add(:original_bg_image, 'Invalid image')
      return
    end

    if original_bg_image.file.size.to_f > 10.megabytes.to_f
      errors.add(:original_bg_image,
                 "Image #{original_bg_image.file.original_filename} should be a maximum size of 10Mb")
      return
    end

    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if original_bg_image.path.nil?

    begin
      magick_image = MiniMagick::Image.open(original_bg_image.path)

      if magick_image.width < 600 || magick_image.height < 300
        errors.add(:original_bg_image, "Image #{original_bg_image.file.original_filename} should be 1000x500px minimum")
      end
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end

  def set_versions
    self.bg_image = original_bg_image.file
  end

  def sanitize_bio
    self.bio = CGI.unescapeHTML(Sanitize.clean(bio.to_s))
  end

  def sanitize_phone
    self.phone = (phone.to_s.length > 5) ? phone : nil
  end

  def bio_text_length
    length = Nokogiri::HTML.parse(bio).inner_text.length
    if length > LONG_TEXTAREA_MAX_LENGTH
      errors.add(:bio, :too_long, count: LONG_TEXTAREA_MAX_LENGTH)
    end
  end

  def user_reindex
    user.multisearch_reindex
  end
end
