# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class ModelEncoderBase
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ModelConcerns::HasErrors

        attr_reader :jwt, :refresh_jwt, :model, :options

        def initialize(model, options = {})
          @model = model
          @options = default_options.merge(options)
          @errors = ActiveModel::Errors.new(self)
          expires_at
          refresh_expires_at
          encode
          encode_refresh
        end

        def encode
          @jwt = JWT.encode(payload, jwt_secret)
        end

        def expires_at
          @expires_at ||= @options[:expires_at] || @options[:exp_minutes].to_i.minutes.from_now
        end

        def refresh_expires_at
          @refresh_expires_at ||= @options[:refresh_expires_at] || @options[:refresh_exp_minutes].to_i.minutes.from_now
        end

        def payload
          raise NotInheritedError
        end

        def jwt_secret
          @model.jwt_secret
        end

        def encode_refresh
          @refresh_jwt = JWT.encode(refresh_payload, jwt_secret)
        end

        def refresh_payload
          raise NotInheritedError
        end

        private

        def default_options
          {
            exp_minutes: Rails.application.credentials.backend.dig(:initialize, :security, :jwt, :access_exp_minutes),
            refresh_exp_minutes: Rails.application.credentials.backend.dig(:initialize, :security, :jwt, :refresh_exp_minutes)
          }
        end
      end
    end
  end
end
