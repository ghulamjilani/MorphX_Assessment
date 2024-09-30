# frozen_string_literal: true

module SearchableJobs
  class UpdatePgSearchDocumentJob < ApplicationJob
    sidekiq_options queue: :low

    def perform(klass, id, _options = {})
      model = klass.classify.constantize.find_by(id: id)
      return unless model.respond_to?(:update_pg_search_document)

      model.update_pg_search_document
    end
  end
end
