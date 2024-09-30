# frozen_string_literal: true

module ModelConcerns::Video::PgSearchable
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
                    additional_attributes: lambda { |video|
                      {
                        age_restrictions: video.session&.age_restrictions,
                        category_id: video.session&.category&.id,
                        channel_id: video.session&.channel_id,
                        channel_type_id: video.session&.channel&.channel_type_id,
                        deleted: video.deleted_at.present?,
                        duration: (video.actual_duration.to_f / 1000).to_i,
                        end_at: video.session&.end_at,
                        fake: video.fake,
                        featured: video.featured,
                        free: begin
                          (video.session&.recorded_purchase_price&.zero? || video.session&.recorded_free) && !video.only_subscription?
                        rescue StandardError
                          true
                        end,
                        listed_at: video.published,
                        model_created_at: video.created_at,
                        popularity: (video.session&.average ? video.session&.average&.avg : 0),
                        private: video.session&.private,
                        published: video.published?,
                        recorded_purchase_price: video.session&.recorded_purchase_price,
                        show_on_home: video.show_on_home,
                        hide_on_home: video.hide_on_home,
                        show_on_profile: video.show_on_profile,
                        start_at: video.session&.start_at,
                        status: video.status,
                        title: video.always_present_title.prepare_for_search,
                        user_id: video.user_id,
                        views_count: video.total_views_count,
                        visible: video.show_on_profile?,
                        promo_start: video.promo_start,
                        promo_end: video.promo_end,
                        promo_weight: video.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    def fulltext_search_data
      [
        title,
        description,
        always_present_title,
        always_present_description,
        session&.custom_description_field_value,
        session&.channel&.title,
        session&.channel&.description,
        tags.map(&:name).join(' ')
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?

      !blocked? && !is_fake? && status_done? && published? && show_on_profile? && session.present? && deleted_at.blank? && channel&.organization&.active_subscription_or_split_revenue?
    end
  end
end
