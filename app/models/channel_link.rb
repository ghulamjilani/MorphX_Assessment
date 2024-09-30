# frozen_string_literal: true
# require_dependency 'url_format_validator'
# require_dependency 'url_formatter'

class ChannelLink < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include UrlFormatter
  include ModelConcerns::ActiveModel::Extensions

  module OembedTypes
    PHOTO = 'photo'
    VIDEO = 'video'
    RICH  = 'rich'
    LINK  = 'link'
  end

  belongs_to :channel, touch: true

  before_validation :format_url
  before_validation :fetch_oembed_description
  before_validation :fetch_oembed_title
  before_validation :fetch_oembed_type
  validate :check_if_valid_http_resource
  validates :url, presence: true
  validates_with UrlFormatValidator

  after_create :extract_into_channel_image

  validates :url, uniqueness: { scope: [:channel] }

  validates :oembed_type, presence: true, inclusion: [
    OembedTypes::VIDEO,
    OembedTypes::RICH,
    OembedTypes::LINK,
    OembedTypes::PHOTO
  ]

  scope :most_relevant, -> { order(place_number: :asc) }

  def thumbnail_url(max_width = 640)
    embedly_thumbnail_url = Immerss::Embedly.oembed_thumbnail_url(url: url, max_width: max_width)
    if embedly_thumbnail_url.nil? and oembed_type.eql? OembedTypes::PHOTO
      url
    else
      embedly_thumbnail_url || 'http://placehold.it/480x360'
    end
  end

  # Return HTML for embedded document
  #
  # @return [String]
  def embedded_html(max_width = 480)
    case oembed_type
    when OembedTypes::PHOTO
      %(<img src="#{url}" />)
    when OembedTypes::VIDEO
      Immerss::Embedly.oembed_html(url: enhanced_video_url, maxwidth: max_width).to_s
    when OembedTypes::RICH
      Immerss::Embedly.oembed_html(url: url, maxwidth: max_width).to_s
    when OembedTypes::LINK
      %(<a href="#{url}" class="embed-link" target="_blank" rel="nofollow">#{Immerss::Embedly.oembed(url: url)[:title] || url.to_s.truncate(50)}</a>)
    else
      ''
    end
  end

  # @see http://embed.ly/docs/endpoints/1/oembed#oembed-types to know about full list of params
  def fetch_oembed_description
    return if description.present? # could be set in Factory or seed data
    return if url.blank?

    oembed = Immerss::Embedly.oembed_from_url(url)
    self.description = oembed[:description]
  end

  # @see http://embed.ly/docs/endpoints/1/oembed#oembed-types to know about full list of params
  def fetch_oembed_title
    return if title.present? # could be set in Factory or seed data
    return if url.blank?

    oembed = Immerss::Embedly.oembed_from_url(url)
    self.title = oembed[:title]
  end

  # @see http://embed.ly/docs/endpoints/1/oembed#oembed-types to know about full list of params
  def fetch_oembed_type
    return if oembed_type.present? # could be set in Factory or seed data
    return if url.blank?

    oembed = Immerss::Embedly.oembed_from_url(url)
    self.oembed_type = oembed[:type]
    logger.info(oembed[:error_message]) if oembed_type == 'error'
  end

  def check_if_valid_http_resource
    return if oembed_type.present? # could be set in Factory or seed data
    return if url.blank?

    fetch_oembed_type
    errors.add(:url, 'must be valid') if oembed_type == 'error'
  end

  def channel_material(width = 320)
    {
      id: id,
      embedded: embedded_html(width).html_safe,
      img_src: thumbnail_url(100),
      type: 'link',
      url: url,
      place_number: place_number,
      description: description
    }
  end

  def slider_material
    channel_material
  end

  private

  def enhanced_video_url
    return url unless url.include?('youtube')
    return url if url.include?('rel=')

    result = "#{url}&rel=0"
    unless /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/.match?(result)
      Airbrake.notify(RuntimeError.new('enhanced url does not seem like a valid one'),
                      parameters: {
                        url: url,
                        result: result
                      })
    end
    result
  end

  def extract_into_channel_image
    return unless oembed_type == OembedTypes::PHOTO

    ExtractChannelPhotoLinkIntoChannelImage.perform_async(id)
  end
end
