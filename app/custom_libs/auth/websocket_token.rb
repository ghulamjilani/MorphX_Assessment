# frozen_string_literal: true

module Auth
  class WebsocketToken
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ModelConcerns::HasErrors

    attr_accessor :id, :abstract_user, :abstract_user_id, :abstract_user_type, :visitor_id, :expires_in

    class << self
      def cache_key(id)
        "cable/auth/#{id}"
      end

      def create(visitor_id:, abstract_user: nil, expires_in: nil)
        token = new(visitor_id:, abstract_user:, expires_in:)
        token.save
        token
      end

      def find(id)
        return nil unless (payload_json = Rails.cache.read(cache_key(id)))

        Rails.cache.delete(cache_key(id))
        payload = JSON.parse(payload_json).symbolize_keys
        abstract_user = if payload[:abstract_user_type].present? && payload[:abstract_user_id].present?
                          payload[:abstract_user_type].classify.constantize.find(payload[:abstract_user_id])
                        end
        visitor_id = payload[:visitor_id]
        new(visitor_id:, abstract_user:, id:)
      rescue StandardError
        nil
      end
    end

    def cache_key
      self.class.cache_key(id)
    end

    def initialize(visitor_id:, abstract_user: nil, expires_in: nil, id: nil)
      super

      @id = id.presence || SecureRandom.hex(16)
      @visitor_id = visitor_id
      @abstract_user = abstract_user
      @expires_in = (expires_in.presence || 5).to_i.seconds

      if @abstract_user.present?
        @abstract_user_id = @abstract_user.id
        @abstract_user_type = @abstract_user.class.name
      end
    end

    def save
      Rails.cache.write(cache_key, payload.to_json, expires_in: @expires_in)
      true
    end

    def payload
      @payload ||= {
        abstract_user_id: @abstract_user_id,
        abstract_user_type: @abstract_user_type,
        visitor_id: @visitor_id
      }
    end
  end
end
