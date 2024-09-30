# frozen_string_literal: true

module ModelConcerns::Shared::HasSecret
  extend ActiveSupport::Concern

  included do
    def self.random_secret
      "\\x#{SecureRandom.hex(16)}"
    end

    def random_secret
      self.class.random_secret
    end
  end
end
