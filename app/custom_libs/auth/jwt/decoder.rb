# frozen_string_literal: true

module Auth
  module Jwt
    class Decoder
      attr_reader :jwt, :model, :errors

      delegate(*%i[jwt model decode decode! valid? validate validate! errors expires_at expired?], to: :decoder)

      def initialize(jwt)
        @jwt = jwt
        validate
      end

      def decoder
        @decoder ||= Decoders::Factory.model_decoder_by_type(type).new(@jwt)
      end

      def type
        payload[:type]
      end

      def payload
        JWT.decode(@jwt, nil, false)[0].symbolize_keys
      rescue StandardError
        {}
      end
    end
  end
end
