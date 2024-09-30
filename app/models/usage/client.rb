# frozen_string_literal: true

module Usage
  class Client
    module Types
      API = 'api'
      MOBILE = 'mobile'
      EMBED = 'embed'
      BROWSER = 'browser'

      ALL = [
        API,
        MOBILE,
        EMBED,
        BROWSER
      ].freeze
    end
  end
end
