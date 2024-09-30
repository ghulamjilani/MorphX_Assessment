# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class ModelDecoderBase
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ModelConcerns::HasErrors

        attr_reader :jwt, :model, :errors

        validate :validate_payload
        validate :validate_expiration

        def klass
          raise NotInheritedError
        end

        def supported_jwt_types
          raise NotInheritedError
        end

        def initialize(jwt)
          @jwt = jwt
          @errors = ActiveModel::Errors.new(self)
          decode
        end

        def decode
          return false unless valid?

          @model = klass.find_by(id: payload[:id])
          return false if @model.blank?

          JWT.decode(jwt, jwt_secret)
          @model
        rescue JWT::DecodeError, JWT::VerificationError, StandardError
          false
        end

        def decode!
          validate!
          @model = klass.find(payload[:id])
          JWT.decode(jwt, jwt_secret)
          @model
        end

        def jwt_secret
          @jwt_secret ||= @model.jwt_secret
        end

        def validate!
          validate_payload!
          validate_expiration!
        end

        def validate_payload!
          validate_payload || raise(::Auth::Jwt::Errors::PayloadValidationError, errors.full_messages_for(:payload).join(';'))
        end

        def validate_payload
          if (missing_keys = required_payload_keys.filter { |key| payload[key].blank? }).present?
            missing_keys.each do |missing_key|
              errors.add(:payload, I18n.t('custom_libs.auth.jwt.decoder.errors.payload.missing_key', missing_key: missing_key))
            end
          end

          unless supported_jwt_types.include?(type)
            errors.add(:payload, I18n.t('custom_libs.auth.jwt.decoder.errors.payload.wrong_type', type: type, class: self.class.name))
          end

          errors.where(:payload).blank?
        end

        def required_payload_keys
          %i[type id exp]
        end

        def validate_expiration!
          validate_expiration || raise(::Auth::Jwt::Errors::JwtExpiredError, errors.full_messages_for(:expires_at).join(';'))
        end

        def validate_expiration
          if expired?
            errors.add(:expires_at, I18n.t('custom_libs.auth.jwt.decoder.errors.expired'))
          end

          errors.where(:expires_at).blank?
        end

        def expired?
          expires_at < Time.now.utc
        end

        def expires_at
          DateTime.strptime(payload[:exp].to_s, '%s')
        rescue Date::Error
          1.hour.ago
        end

        def type
          payload[:type]
        end

        def payload
          @payload ||= JWT.decode(@jwt, nil, false)[0].symbolize_keys
        rescue StandardError
          @payload = {}
        end
      end
    end
  end
end
