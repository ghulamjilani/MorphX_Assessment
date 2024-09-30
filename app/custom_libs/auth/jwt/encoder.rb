# frozen_string_literal: true

module Auth
  module Jwt
    class Encoder
      attr_reader :type, :model, :jwt, :refresh_jwt, :expires_at, :refresh_expires_at

      def initialize(type:, model: nil, options: {})
        @type = type
        @model = model
        @options = options
      end

      delegate(*%i[encode encode_refresh jwt refresh_jwt expires_at refresh_expires_at options], to: :encoder)

      def encoder
        @encoder ||= Encoders::Factory.model_encoder_by_type(type).new(model, @options)
      end
    end
  end
end
