# frozen_string_literal: true

# {
#     "status": 0,
#     "keystatus": "valid",
#     "result": [
#         {
#             "barcode": "9780140157376",
#             "type": "ISBN",
#             "details": {
#                 "product_name": "Haroun and the Sea of Stories",
#                 "prod_details": "Media > Books",
#                 "barcode_formats": "ISBN 0140157379, ISBN 9780140157376",
#                 "category": "Media > Books",
#                 "author": "",
#                 "publisher": "",
#                 "artist": "",
#                 "manufacturer": "",
#                 "actor": "",
#                 "director": "",
#                 "manufacturer_part_number": "0978014015737",
#                 "model": "",
#                 "features": "",
#                 "long_description": "Discover Haroun and the Sea of Stories, Salman Rushdie's classic fantasy novel Set in an exotic Eastern landscape peopled by magicians and fantastic talking animals, Salman Rushdie's classic children's novel Haroun and the Sea of Stories inhabits the same imaginative space as The Lord of the Rings, The Alchemist, and The Wizard of Oz. In this captivating work of fantasy from the author of Midnight's Children and The Enchantress of Florence, Haroun sets out on an adventure to restore the poisoned source of the sea of stories. On the way, he encounters many foes, all intent on draining the sea of all its storytelling powers. Also look for Salman Rushdie's next book, Joseph Anton: A Memoir, coming fall 2012. \"Though there is darkness and silence at the center of Chup, most of \"Haroun and the Sea of Stories\" is full of comic energy and lively verbal invention. .Though the book] is sure to be enjoyed by children, it also contains amusements for adults.\" - \"The New York Times\"",
#                 "brand": "",
#                 "label": "",
#                 "clothing_size": "",
#                 "color": "",
#                 "genre": "",
#                 "height": "",
#                 "length": "",
#                 "width": "",
#                 "weight": ""
#             },
#             "images": {
#                 "0": "https://images.barcodelookup.com/134/1342375-1.jpg"
#             },
#             "stores": {
#                 "0": {
#                     "min_price": "3.95",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "http://www.betterworldbooks.com/haroun-and-the-sea-of-stories-id-9780140157376.aspx",
#                     "advertiser": "BetterWorld.com - New, Used, Rare Books & Textbooks",
#                     "currency": "$"
#                 },
#                 "1": {
#                     "min_price": "3.79",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "https://www.thriftbooks.com/w/haroun-and-the-sea-of-stories_salman-rushdie/254624/#isbn=0140157379",
#                     "advertiser": "ThriftBooks.com",
#                     "currency": "$"
#                 },
#                 "2": {
#                     "min_price": "12.92",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "http://www.chapters.indigo.ca/books/item/9780140157376-item.html",
#                     "advertiser": "Indigo Books & Music",
#                     "currency": "$"
#                 },
#                 "3": {
#                     "min_price": "14.69",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "http://www.walmart.com/ip/Haroun-and-the-Sea-of-Stories/518868",
#                     "advertiser": "Wal-Mart.com USA, LLC",
#                     "currency": "$"
#                 },
#                 "4": {
#                     "min_price": "16.00",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "http://www.booksamillion.com/p/Haroun-Sea-Stories/Salman-Rushdie/9780140157376",
#                     "advertiser": "BOOKSAMILLION.COM",
#                     "currency": "$"
#                 },
#                 "5": {
#                     "min_price": "16.00",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "https://www.newegg.com/Product/Product.aspx?Item=9SIADE461Y9464&nm_mc=AFC-C8Junction-MKPL&cm_mmc=AFC-C8Junction-MKPL-_-Books-_-Penguin+Group-_-9SIADE461Y9464",
#                     "advertiser": "Newegg.com",
#                     "currency": "$"
#                 },
#                 "6": {
#                     "min_price": "17.20",
#                     "max_price": "",
#                     "title": "Haroun and the Sea of Stories",
#                     "category": "Media > Books",
#                     "manufacturer": "",
#                     "url": "https://www.neweggbusiness.com/Product/Product.aspx?Item=9SIV0UN4FF1359&nm_mc=afc-cjb2b&cm_mmc=afc-cjb2b-_-Books-_-Penguin+Group-_-9SIV0UN4FF1359",
#                     "advertiser": "Newegg Business",
#                     "currency": "$"
#                 }
#             },
#             "reviews": {}
#         }
#     ]
# }
module Sales::Parsers
  class BarcodeLookup < ProductParser
    SPECS_KEYS = %w[author publisher artist manufacturer manufacturer_part_number actor director model features brand
                    label clothing_size color genre height length width weight].freeze

    def initialize(options)
      super(:barcode_lookup, options)
      @error_message = nil
    end

    # Performs a product lookup by barcode on brcodelookup
    def lookup
      result = Rails.cache.read(@key)
      if result
        result = JSON.parse(result)
      elsif @options[:barcode]
        begin
          uri = get_url(@options[:barcode])
          @resp = RestClient.get(uri, { content_type: :json })
          result = JSON.parse(@resp)
          if result['result'].present? && result['result'][0]['barcode']
            Rails.cache.write(@key, result.to_json, expires_in: 1.week)
          else
            Rails.logger.debug "BarcodeLookup return empty result === #{@options}"
            Rails.logger.debug @resp
            return {}
          end
        rescue StandardError => e
          Rails.logger.debug "BarcodeLookup lookup failed === #{@options}"
          Rails.logger.debug e.message
          Rails.logger.debug @resp
          return {}
        end
      else
        @error_message = 'Barcode option is required'
        return {}
      end
      if result['result'].present?
        parse_data(result['result'])
      else
        Rails.logger.debug "BarcodeLookup return empty result === #{@options}"
        Rails.logger.debug result.to_json
        @error_message = 'BarcodeLookup return empty result'
        {}
      end
    end

    private

    def get_url(barcode)
      # barcode = '9780140157376'
      # barcode = '3605971333781'
      barcode_service_key = Rails.application.credentials.backend.dig(:initialize, :barcodelookup,
                                                                      :api_key) || ENV['BARCODELOOKUP_KEY']
      "https://www.barcodelookup.com/restapi?barcode=#{barcode}&formatted=y&key=#{barcode_service_key}"
    end

    def parse_data(data)
      data = data[0] # for demo lets use only first result
      product = Hashie::Mash.new

      product.title = data['details']['product_name']
      product.barcodes = data['details']['barcode_formats']
      product.description = data['details']['long_description']
      product.specifications = format_specs(data['details'])
      product.stores_attributes = format_stores(data['stores'])
      product.product_image_attributes = format_images(data['images'])
      product.partner = 'barcode_lookup'
      # take first store info
      if product.stores_attributes.present?
        product.url = product.stores_attributes.first[:url]
        product.price_cents = product.stores_attributes.first[:min_price_cents]
        product.price_currency = product.stores_attributes.first[:price_currency]
      else
        product.url = ''
        product.price_cents = 0
        product.price_currency = 'USD'
      end
      product.raw_info = data.to_json
      product
    end

    def format_specs(data)
      formatted_specs = []
      SPECS_KEYS.each do |key|
        formatted_specs.push("#{key.humanize}: #{data[key]}") if data[key].present?
      end
      formatted_specs.join(', ')
    end

    def format_stores(data)
      return [] if data.blank?

      stores = []
      Monetize.assume_from_symbol = true
      data.values.each do |store|
        obj = {
          min_price_cents: Monetize.parse(store['currency'] + store['min_price']).cents,
          max_price_cents: Monetize.parse(store['currency'] + store['max_price']).cents,
          price_currency: Monetize.parse(store['currency'] + store['min_price']).currency.to_s,
          category: store['category'],
          manufacturer: store['manufacturer'],
          advertiser: store['advertiser'],
          url: store['url']
        }
        stores.push(obj)
      end
      Monetize.assume_from_symbol = false
      stores
    end

    def format_images(data)
      images = data.is_a?(Hash) ? data.values : data
      { remote_original_url: images.first }
    end
  end
end
