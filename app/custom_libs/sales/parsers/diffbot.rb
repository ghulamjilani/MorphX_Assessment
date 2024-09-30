# frozen_string_literal: true

# https://www.diffbot.com/dev/docs/product/
module Sales::Parsers
  class Diffbot < ProductParser
    def initialize(options)
      super(:diffbot, options)
    end

    # Performs a product info fetching by url on Diffbot
    def fetch
      result = Rails.cache.read(@key)
      unless result
        begin
          uri = get_uri
          @resp = RestClient.get(uri, { content_type: :json })
          result = JSON.parse(@resp)
        rescue StandardError => e
          # Trying to find where and why fetch product action returns empty data
          Rails.logger.debug "Diffbot fetch failed === #{@options[:url]}"
          Rails.logger.debug e.message
          Rails.logger.debug @resp
          Airbrake.notify(RuntimeError.new('Diffbot product fetch failed'),
                          parameters: {
                            message: e.message,
                            url: @options[:url],
                            diffbot_response: @resp
                          })
        end
      end

      if result.blank? || result['objects'].blank?
        Rails.logger.debug "Diffbot return empty result === #{@options[:url]}"
        Rails.logger.debug result.to_json
        return {}
      else
        Rails.cache.write(@key, result, expires_in: 1.week)
      end

      parse_data(result)
    end

    private

    def parse_data(data)
      product = Hashie::Mash.new
      data = data['objects'].to_a.first

      product.url = @options[:url] || data['pageUrl']
      product.title = data['title']
      product.description = data['text']
      product.specifications = format_specs(data['specs'])
      product.images = format_images(data['images'])
      product.price = format_price(data)
      product
    end

    def get_uri
      params = {
        token: ENV['DIFFBOT_TOKEN'],
        url: @options[:url],
        fields: 'pageUrl,title,text,offerPrice,regularPrice,specs,images'
      }
      uri = URI(ENV['DIFFBOT_URL'])
      uri.query = params.to_param
      uri.to_s
    end

    def format_specs(specs)
      return '' if specs.blank?

      formatted_specs = []
      specs.each_pair do |key, value|
        formatted_specs << "#{key.humanize}: #{value}"
      end
      formatted_specs.join(', ')
    end

    def format_images(images)
      images.to_a.map { |img| img['url'] }.uniq.compact
    end

    def format_price(data)
      Monetize.parse(data['offerPrice'] || data['regularPrice']).format
    rescue StandardError
      if data['offerPriceDetails'] && data['offerPriceDetails']['symbol'] && data['offerPriceDetails']['amount']
        Monetize.parse(data['offerPriceDetails']['symbol'] + data['offerPriceDetails']['amount'].to_s).format
      end
    end
  end
end
