# frozen_string_literal: true

require 'rest-client'
module Sales::Parsers
  class Custom < ProductParser
    def initialize(options)
      super(:custom, options)
    end

    # Performs a product info fetching by url on Facebook
    def fetch
      begin
        uri = URI.parse(@options[:url])
        resp = Net::HTTP.get(uri) # don't use open because it will process all data (eg. video)
        doc = Nokogiri::HTML(resp, nil, 'UTF-8')
        result = parse_data(doc)
      rescue StandardError => e
        # Trying to find where and why fetch product action returns empty data
        Rails.logger.debug "custom parser fetch failed === #{@options[:url]}"
        Rails.logger.debug e.message
      end

      if result.blank?
        Rails.logger.debug "custom parser return empty result === #{@options[:url]}"
        Rails.logger.debug result.to_json

        return {}
      end

      result
    end

    private

    def parse_data(doc)
      product = Hashie::Mash.new

      doc.xpath('//head//meta|//body//meta').each do |meta|
        if meta['property'] == 'og:title'
          product.title ||= meta['content']
        elsif meta['property'] == 'og:description' || meta['name'] == 'description'
          product.short_description ||= meta['content']
        elsif meta['property'] == 'og:url'
          product.url ||= meta['content']
        elsif meta['property'] == 'og:image'
          product.images ||= [meta['content']]
        end
      end
      product
    end
  end
end
