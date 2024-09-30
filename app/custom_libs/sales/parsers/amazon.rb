# frozen_string_literal: true

Amazon::Ecs.configure do |options|
  options[:AWS_access_key_id] = ENV['S3_ACCESS_KEY_ID']
  options[:AWS_secret_key] = ENV['S3_SECRET_ACCESS_KEY']
  # options[:associate_tag] = '[your associate tag]'
end
module Sales::Parsers
  class Amazon
    RESPONSE_GROUPS = 'ItemAttributes,EditorialReview,Images,BrowseNodes,OfferListings'
    HOST_REGEXPS = {
      au: %r{amazon\.com\.au/},
      br: %r{amazon\.com\.br/},
      ca: %r{amazon\.ca/},
      cn: %r{amazon\.cn/},
      de: %r{amazon\.de/},
      es: %r{amazon\.es/},
      fr: %r{amazon\.fr/},
      in: %r{amazon\.in/},
      it: %r{amazon\.it/},
      jp: %r{amazon\.co\.jp/},
      mx: %r{amazon\.com\.mx/},
      nl: %r{amazon\.nl/},
      uk: %r{amazon\.co\.uk/},
      us: %r{amazon\.com/}
    }.freeze
    ASIN_REGEXP = %r{/([A-Z0-9]{10})}.freeze

    def initialize(country_code, global = true)
      @country_code = country_code
      @global = global
    end

    # Performs a product lookup (by asin) on Amazon
    def lookup(product, options = {})
      lookup_ways = parse_lookup_parameters(product)

      result = nil

      # Let's try to do a lookup via ASIN first, and if not via UPC
      # unless `options[:upc]` was specified
      lookup_ways.each do |attribute, value|
        # If the current lookup value is empty, then move to the next one
        next if value.blank?

        #
        # key = "#{redis_partner_key}-lookup-#{attribute}-#{value}"
        # result = $redis.get(key)

        # if result
        # Rails.logger.info "getting data from cache: #{key}"
        # result = JSON.parse(result)
        # else
        #   p "getting data from Amazon: #{key}"
        begin
          # If we are doing a lookup via UPC
          result = case attribute
                   when :upc
                     lookup_by_upc(value, options)
                   # If we are doing a lookup via EAN13
                   when :ean13
                     lookup_by_ean13(value, options)
                   # If not, we are doing a lookup via ASIN
                   else
                     ::Amazon::Ecs.item_lookup(value, amazon_options_mapping(options, 'ASIN')).doc.to_hash
                     # Cache results on redis
                   end
        rescue StandardError => e
          result = {}
        end
        if result.present?
          # $redis.set(key, result.to_json)
          # $redis.expire(key, 24.hours)
        end
        # end
        break if result.present?
      end

      # Parse results
      # parse_lookup_data(result)
      result
    end

    # Performs a product lookup (by UPC) on Amazon
    def lookup_by_upc(upc, options = {})
      ::Amazon::Ecs.item_lookup(upc, amazon_options_mapping(options, 'UPC')).doc.to_hash
    end

    # Performs a product lookup (by EAN13) on Amazon
    def lookup_by_ean13(ean13, options = {})
      ::Amazon::Ecs.item_lookup(ean13, amazon_options_mapping(options, 'EAN')).doc.to_hash
    end

    private

    def parse_lookup_parameters(parameters)
      lookup_ways = {
        asin: '',
        upc: '',
        ean13: ''
      }

      if parameters.is_a?(Hash)
        lookup_ways[:asin] = parameters[:asin]
        lookup_ways[:upc] = parameters[:upc]
        lookup_ways[:ean13] = parameters[:ean13]
      end
      # Delete empty values
      lookup_ways.delete_if { |_, v| v.blank? }
    end

    def amazon_options_mapping(options, id_type = nil)
      # TODO: search_index parameter?
      amazon_options = { search_index: 'All',
                         item_page: options[:page] || 1,
                         response_group: RESPONSE_GROUPS }

      amazon_options[:country] = @country_code unless @global

      # The type of search we will make
      amazon_options[:idType] = id_type if id_type.present?

      # If we are sarching by ASIN, we can't include the following parameters
      if id_type == 'ASIN'
        amazon_options.delete(:search_index)
        amazon_options.delete(:item_page)
      end

      amazon_options
    end
  end
end
