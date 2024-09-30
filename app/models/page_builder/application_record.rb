# frozen_string_literal: true

module PageBuilder
  class ApplicationRecord < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection
    include ModelConcerns::ActiveModel::Extensions

    self.abstract_class = true
    self.table_name_prefix = 'pb_'

    validates :body, presence: true

    validate :body_validation

    after_commit :clear_cache_keys

    def body_validation
      errors.add(:body, 'is not a valid template') unless JSON.parse(body).is_a?(Hash)
    rescue JSON::ParserError
      errors.add(:body, 'is not a valid json')
    end

    def template_cache_key
      raise AbstractMethodNotInheritedError
    end

    private

    def clear_cache_keys
      Rails.cache.delete_matched("#{Regexp.quote(template_cache_key)}*")
      Rails.cache.delete_matched("jbuilder/views/#{Regexp.quote(template_cache_key)}*")
    end
  end
end
