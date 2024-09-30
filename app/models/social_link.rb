# frozen_string_literal: true
class SocialLink < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  module Providers
    FACEBOOK  = 'facebook'
    GPLUS     = 'google+'
    INSTAGRAM = 'instagram'
    LINKEDIN  = 'linkedin'
    EXPLICIT  = 'explicit'
    TWITTER   = 'twitter'
    YOUTUBE   = 'youtube'
    TELEGRAM = 'telegram'

    NAMES = {
      'facebook': 'Facebook',
      'google+': 'Google +',
      'instagram': 'Instagram',
      'linkedin': 'LinkedIn',
      'twitter': 'Twitter',
      'youtube': 'Youtube',
      'explicit': 'My Site',
      'telegram': 'Telegram'
    }.freeze

    URLS = {
      'facebook': 'https://facebook.com/',
      'google+': 'https://plus.google.com/',
      'instagram': 'https://instagram.com/',
      'linkedin': 'https://linkedin.com/',
      'twitter': 'https://twitter.com/',
      'youtube': 'https://youtube.com/',
      'telegram': 'https://t.me/'
    }.freeze

    # NOTE: do not change order of providers in ORDERED_ALL
    #      it is used for outputing it in right order(important accordingly to Alex)
    ORDERED_ALL = [
      EXPLICIT,
      FACEBOOK,
      GPLUS,
      INSTAGRAM,
      LINKEDIN,
      TWITTER,
      YOUTUBE,
      TELEGRAM
    ].freeze
  end

  belongs_to :entity, polymorphic: true

  validates :provider, presence: true, inclusion: { in: Providers::ORDERED_ALL }
  validates :entity_id, uniqueness: { scope: %i[provider entity_type] }

  validate :validate_proper_domain, if: :validate_proper_domain?
  validate :validate_url

  before_save :normalize_link
  def marked_for_destruction?
    link.to_s.strip.blank? and !new_record?
  end

  # because validation is missing for various providers
  # and their links were corrupted very often
  # @return [String]
  def link_as_url
    # unless compose_url =~ URI::regexp
    #   Airbrake.notify(RuntimeError.new('invalid social link format'),
    #                   parameters: {
    #                     result: result,
    #                     social_link: self.inspect
    #                   })
    # end
    compose_url
  end

  scope :twitter, -> { where(provider: Providers::TWITTER) }

  private

  def validate_proper_domain
    u = begin
      URI.parse(link_as_url.strip)
    rescue StandardError
      nil
    end
    if u && linkedin_profile_domains.exclude?(u.host) && u.host != 'www.linkedin.com' && u.host != 'linkedin.com'
      errors.add(:link, %("#{link_as_url}" does not seem like a valid LinkedIn profile URL))
    end
  end

  def validate_proper_domain?
    linkedin? && link_changed?
  end

  def validate_url
    u = begin
      URI.parse(link_as_url.strip)
    rescue StandardError
      nil
    end
    errors.add(:link, %("#{link_as_url}" does not seem like a valid URL)) if u.nil?
  end

  def linkedin?
    link.present? && provider.to_s == Providers::LINKEDIN
  end

  def compose_url
    _link = link.dup.to_s.gsub('www:', 'www.').gsub('//', '/')
    _link.strip!

    # NOTE: normalize downcases protocol name and host name
    # @see http://ruby-doc.org/stdlib-2.0.0/libdoc/uri/rdoc/URI/Generic.html#method-i-normalize
    begin
      _link = URI.parse(_link).normalize.to_s
    rescue URI::InvalidURIError => e
      Rails.logger.debug e.backtrace
      Rails.logger.debug e.message
    end

    _link.gsub!(%r{^https?\:/}) { |m| "#{m}/" } if %r{^https?\:/[^/]}.match?(_link)
    _link.gsub!(%r{^[\@/]}, '') if _link.start_with?('@', '/')

    return _link if [Providers::EXPLICIT, Providers::LINKEDIN].exclude?(provider) &&
                    _link.start_with?(Providers::URLS[provider.to_sym])

    result = case provider
             when Providers::EXPLICIT
               begin
                 u = URI.parse(_link.strip)
                 u.scheme.blank? ? "https://#{_link.strip}" : _link
               rescue StandardError
                 _link
               end
             when Providers::GPLUS
               _link.gsub(%r{(https?://)?(www\.)?(plus\.google\.com/)?}i, '')
             when Providers::TWITTER
               _link.gsub(%r{(https?://)?(www\.)?(twitter\.com/)?}i, '')
             when Providers::FACEBOOK
               _link.gsub(%r{(https?://)?(www\.)?(facebook\.com/)?}i, '')
             when Providers::YOUTUBE
               _link.gsub(%r{(https?://)?(www\.)?(youtube\.com/)?}i, '')
             when Providers::TELEGRAM
               _link.gsub(%r{(https?://)?(t\.me/)?}i, '')
             when Providers::LINKEDIN
               slug = _link.gsub(%r{(https?://)?(www\.)?([a-z]+\.)?(linkedin\.com/(in|pub)/)}i, '')
               path = %r{linkedin\.com/pub}.match?(_link) ? 'pub/' : 'in/'
               Providers::URLS[:linkedin] + path + slug
             when Providers::INSTAGRAM
               _link.gsub(%r{(https?://)?(www\.)?(instagram\.com/)?}i, '')
             else
               raise ArgumentError, _link
             end.strip
    [Providers::EXPLICIT, Providers::LINKEDIN].include?(provider) ? result : Providers::URLS[provider.to_sym] + result
  end

  def normalize_link
    link = compose_url
  end
end
