# frozen_string_literal: true

module Webrtcservice
  module Chat
    class Token
      def self.access_token(identity)
        credentials = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :chat)
        raise 'backend:initialize:webrtcservice:chat in application credentials is required' unless credentials

        token = Webrtcservice::JWT::AccessToken.new(
          credentials[:account_sid],
          credentials[:api_key],
          credentials[:api_secret],
          [],
          identity: identity
        )
        grant = Webrtcservice::JWT::AccessToken::ChatGrant.new
        grant.service_sid = credentials[:chat_sid]
        token.add_grant(grant)
        token.to_jwt
      end
    end
  end
end
