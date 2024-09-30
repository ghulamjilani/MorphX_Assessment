# frozen_string_literal: true

module Sales
  class ProductInfo
    def initialize(user = nil)
      @user = user
    end

    def lookup(options)
      @barcode = options[:barcode]
      return {} unless @barcode

      @parsers = [Parsers::BarcodeLookup]
      threads = []
      @parsers.each do |parser|
        threads << Thread.new { parser.new(barcode: @barcode).lookup }
      end
      results = []
      threads.each do |t|
        results << t.value
      end
      # Remove empty results
      results.reject!(&:blank?)
      if results.blank?
        Rails.logger.debug "No product info fetched === barcode: #{@barcode}"
        return {}
      end
      results.first
    end

    def fetch(options)
      @url = options[:url]
      return {} unless @url

      @parsers = [Parsers::Diffbot, Parsers::Facebook, Parsers::Custom]
      product = ::Shop::Product.new(url: @url)
      product.send(:format_url)
      @product_url_handler = Sales::ProductUrl.new(@url, @user)
      @product_url_handler.extract
      # try to provide direct url to product because
      # user can pass short url that perform redirect that diffbot doesn't like
      @direct_url = (@product_url_handler.direct_url || @product_url_handler.uri).to_s

      threads = []
      @parsers.each do |parser|
        threads << Thread.new { parser.new(url: @direct_url).fetch }
      end
      # Wait for threads to finish and collect the results
      results = []
      threads.each do |t|
        results << t.value
      end

      # Remove empty results
      results.reject!(&:blank?)
      if results.blank?
        Rails.logger.debug "No product info fetched === original url: #{@url} === direct url: #{@direct_url}"
        return {}
      end

      product = results.first
      (results - [product]).each do |data|
        product.title = data.title if product.title.blank?
        product.description = data.description if product.description.blank?
        product.short_description = data.short_description if product.short_description.blank?
        product.specifications = data.specifications if product.specifications.blank?
        product.images = [product.images.to_a, data.images.to_a].flatten.compact.uniq
        product.price = data.price if product.price.blank?
      end

      product.url = @url # save original url that we received from user
      product
    end
  end
end
