# frozen_string_literal: true

module ModelConcerns::Recording::PgSearchable
  extend ActiveSupport::Concern
  include ModelConcerns::PgSearchable

  included do
    pg_search_scope :search_by_name,
                    against: %i[title description],
                    using: {
                      trigram: {
                        threshold: 0.1
                      },
                      tsearch: {
                        dictionary: 'english',
                        prefix: false,
                        negation: true
                      }
                    }

    multisearchable against: [:fulltext_search_data],
                    if: :available_for_search?,
                    additional_attributes: lambda { |recording|
                      {
                        category_id: recording.channel&.category&.id,
                        channel_id: recording.channel_id,
                        channel_type_id: recording.channel&.channel_type_id,
                        duration: (recording.actual_duration.to_f / 1000).to_i,
                        fake: recording.fake,
                        free: recording.free? && !recording.only_subscription?,
                        listed_at: recording.published,
                        model_created_at: recording.created_at,
                        popularity: (recording.average ? recording.average.avg : 0),
                        private: recording.private,
                        published: recording.published?,
                        purchase_price: recording.purchase_price,
                        show_on_home: recording.show_on_home,
                        hide_on_home: recording.hide_on_home,
                        status: recording.status,
                        title: recording.always_present_title.prepare_for_search,
                        user_id: recording.organizer&.id,
                        views_count: recording.views_count,
                        visible: recording.visible?,
                        promo_start: recording.promo_start,
                        promo_end: recording.promo_end,
                        promo_weight: recording.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    def fulltext_search_data
      [
        title,
        description,
        channel&.title,
        channel&.description,
        tags.map(&:name).join(' ')
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?

      !blocked? && !is_fake? && done? && visible? && deleted_at.blank? && published? && channel&.available_for_search? && channel&.organization&.active_subscription_or_split_revenue?
    end
  end
end
