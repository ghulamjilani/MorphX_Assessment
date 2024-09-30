# frozen_string_literal: true

module Pundit
  class NotAuthorizedError < Error
    attr_reader :query, :record, :policy

    def initialize(options = {})
      if options.is_a? String
        message = options
      else
        @query  = options[:query]
        @record = options[:record]
        @policy = options[:policy]

        message = options.fetch(:message) do
          I18n.t("pundit.errors.#{@policy.class.name.underscore.parameterize.underscore}.#{query}",
                 default: I18n.t('pundit.default'))
        rescue StandardError
          "not allowed to #{query} this #{record.class}"
        end
      end

      super(message)
    end
  end
end
