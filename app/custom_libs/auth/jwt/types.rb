# frozen_string_literal: true

module Auth
  module Jwt
    module Types
      USER_TOKEN_REFRESH = 'refresh'
      USER_TOKEN = 'user'

      GUEST_REFRESH = 'refresh_guest'
      GUEST = 'guest'

      ORGANIZATION = 'organization'
      USAGE = 'usage'

      ORGANIZATION_INTEGRATION = 'organization_integration'

      ALL = [
        USER_TOKEN,
        USER_TOKEN_REFRESH,
        GUEST,
        GUEST_REFRESH,
        ORGANIZATION,
        USAGE,
        ORGANIZATION_INTEGRATION
      ].freeze
    end
  end
end
