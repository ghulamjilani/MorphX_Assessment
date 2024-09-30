# frozen_string_literal: true

module Usage
  class << self
    def config
      @config ||= Rails.application.credentials.global[:usage].merge(Rails.application.credentials.backend.dig(:initialize, :usage))
    end
  end
end
