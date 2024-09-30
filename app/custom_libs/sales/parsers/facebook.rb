# frozen_string_literal: true

# https://developers.facebook.com/tools/explorer/
require 'rest-client'
module Sales::Parsers
  class Facebook < ProductParser
    def initialize(options)
      super(:facebook, options)
    end

    # Performs a product info fetching by url on Facebook
    def fetch
      result = Rails.cache.read(@key)
      unless result
        begin
          uri = get_uri
          resp = RestClient.post(uri, { id: @options[:url] }, { content_type: :json })
          result = JSON.parse(resp)
        rescue StandardError => e
          # Trying to find where and why fetch product action returns empty data
          Rails.logger.debug "Facebook fetch failed === #{@options[:url]}"
          Rails.logger.debug e.message
        end
      end

      if result.blank?
        Rails.logger.debug "Facebook return empty result === #{@options[:url]}"
        Rails.logger.debug result.to_json

        Rails.cache.delete(@key)
        return {}
      else
        Rails.cache.write(@key, result, expires_in: 1.week)
      end

      parse_data(result)
    end

    private

    def parse_data(data)
      product = Hashie::Mash.new

      product.url = @options[:url] || data['url']
      product.title = data['title']
      product.short_description = data['description']
      product.images = format_images(data['image'])
      product
    end

    def get_uri
      facebook_graph_url = Rails.application.credentials.backend.dig(:initialize, :parsers, :facebook, :graph_url)
      version = Rails.application.credentials.backend.dig(:initialize, :parsers, :facebook, :graph_version) || '15.0'
      uri = URI("#{facebook_graph_url}v#{version}")
      uri.query = { access_token: get_fb_access_token }.to_param
      uri.to_s
    end

    def get_fb_access_token
      # TODO: cache it?
      facebook_conf = Rails.application.credentials.backend.dig(:initialize, :parsers, :facebook)
      @oauth = Koala::Facebook::OAuth.new(facebook_conf[:app_id], facebook_conf[:app_secret])
      @oauth.get_app_access_token
    end

    def format_images(images)
      images.to_a.map { |img| img['url'] }.uniq.compact
    end
  end
end
