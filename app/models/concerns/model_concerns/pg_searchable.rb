# frozen_string_literal: true

module ModelConcerns::PgSearchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  included do
    class << self
      def fulltext_search(query)
        ids = get_pg_documents_relation(query.prepare_for_search).pluck :searchable_id
        where(id: ids)
      end

      def get_pg_documents_relation(*args)
        if args.reject { |arg| arg.to_s.empty? }.present?
          PgSearchDocument.search(*args).where(searchable_type: name)
        else
          PgSearchDocument.where(nil).where(searchable_type: name)
        end
      end

      def multisearch_reindex
        PgSearch::Multisearch.rebuild(self)
      end
    end

    after_commit :schedule_update_pg_search_document_promo
    after_commit :schedule_update_pg_search_document
    after_touch :schedule_update_pg_search_document

    def schedule_update_pg_search_document
      (update_pg_search_document_now and return) if update_pg_search_document_now?

      unless SidekiqSystem::Schedule.exists?(SearchableJobs::UpdatePgSearchDocumentJob, self.class.name, id)
        SearchableJobs::UpdatePgSearchDocumentJob.perform_at(20.seconds.from_now, self.class.name, id)
      end
    end

    def schedule_update_pg_search_document_promo
      if saved_change_to_promo_start?
        SidekiqSystem::Schedule.remove(SearchableJobs::UpdatePgSearchDocumentJob, self.class.to_s, id, { 'after_promo_start' => true })
        SearchableJobs::UpdatePgSearchDocumentJob.perform_at(promo_start, self.class.name, id, { 'after_promo_start' => true }) if promo_start.present?
      end

      if saved_change_to_promo_end?
        SidekiqSystem::Schedule.remove(SearchableJobs::UpdatePgSearchDocumentJob, self.class.to_s, id, { 'after_promo_end' => true })
        SearchableJobs::UpdatePgSearchDocumentJob.perform_at(promo_end, self.class.name, id, { 'after_promo_end' => true }) if promo_end.present?
      end
    end

    def update_pg_search_document_now?
      instance_variable_get(:@_new_record_before_last_commit) ||
        saved_change_to_promo_weight? ||
        saved_change_to_promo_start? ||
        saved_change_to_promo_end?
    end

    def update_pg_search_document_now
      SidekiqSystem::Queue.remove(SearchableJobs::UpdatePgSearchDocumentJob, self.class.name, id)
      update_pg_search_document
    end

    def create_pg_search_document(pg_search_document_attrs)
      super(pg_search_document_attrs)
    rescue ActiveRecord::RecordNotUnique
      pg_search_document
    end
  end
end
