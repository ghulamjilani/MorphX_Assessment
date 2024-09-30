# frozen_string_literal: true

module Sales::Parsers
  class ProductParser
    # This class has been added for documentation purposes
    # Url Parsers don't necessarily have to inherit from this class. We will be using
    # duck-typing. They just need to implement the following methods:
    #
    # --- fetch ---
    #
    # This method will be used to fetch product's info by the specified url
    #
    # It will return a Hashie::Mash obj.
    #

    def initialize(partner, options = {})
      @partner = partner
      @options = options
      # if @options[:url]
      #   @options[:url] = URI.decode(@options[:url])
      # end
      @key = cache_key
    end

    def cache_key
      "#{@partner}-fetch-#{@options}"
    end
  end
end
