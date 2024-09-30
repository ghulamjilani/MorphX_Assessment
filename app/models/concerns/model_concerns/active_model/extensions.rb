# frozen_string_literal: true

module ModelConcerns::ActiveModel
  module Extensions
    extend ActiveSupport::Concern

    included do
      def pretty_errors
        errors.messages.inject({}) do |res, e|
          keys = e[0].to_s.split('.')
          if keys.length.eql? 1
            res[keys[0]] ||= e[1][0]
          else
            sub_hash = keys.reverse.inject({}) do |_res, el|
              val = if keys.last.eql? el
                      e[1][0]
                    else
                      _res
                    end
              { el => val }
            end
            res.deep_merge! sub_hash
          end
          res
        end
      end

      def full_errors(separator = '. ')
        errors.full_messages.join(separator)
      end
    end
  end
end
