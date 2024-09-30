# frozen_string_literal: true

module ModelConcerns::Session::PgSearchable
  extend ActiveSupport::Concern
  include ModelConcerns::PgSearchable

  included do
    after_commit :update_pg_search_models, if: proc { |session|
      session.saved_change_to_fake? ||
        session.saved_change_to_status?
    }

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
                    additional_attributes: lambda { |session|
                      {
                        adult: session.adult,
                        age_restrictions: session.age_restrictions,
                        category_id: session.category&.id,
                        channel_id: session.channel_id,
                        channel_type_id: session.channel&.channel_type_id,
                        duration: session.duration * 60,
                        end_at: (session.stopped_at || session.room&.actual_end_at || session.end_at),
                        fake: session.fake,
                        free: begin
                          ((!session.livestream_purchase_price.nil? && session.livestream_purchase_price.zero?) ||
                            (!session.immersive_purchase_price.nil? && session.immersive_purchase_price.zero?)) &&
                            !session.only_subscription?
                        rescue StandardError
                          true
                        end,
                        immersive_purchase_price: session.immersive_purchase_price,
                        listed_at: session.start_at,
                        livestream_purchase_price: session.livestream_purchase_price,
                        model_created_at: session.start_at,
                        popularity: (session.average ? session.average.avg : 0),
                        private: session.private,
                        recorded_purchase_price: session.recorded_purchase_price,
                        show_on_home: session.show_on_home,
                        hide_on_home: session.hide_on_home,
                        start_at_and_duration: session.start_at + session.duration.minutes,
                        start_at: session.start_at,
                        status: session.status,
                        title: session.always_present_title.prepare_for_search,
                        user_id: session&.organizer&.id || -1,
                        views_count: session.views_count,
                        promo_start: session.promo_start,
                        promo_end: session.promo_end,
                        promo_weight: session.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    def fulltext_search_data
      [
        title,
        description,
        custom_description_field_value,
        channel.title,
        channel.description,
        channel.tags.map(&:name).join(' '),
        presenter&.user&.public_display_name
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?

      !blocked? &&
        !private &&
        (published? || status == ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED) &&
        stopped_at.blank? &&
        cancelled_at.blank? &&
        !is_fake? &&
        end_at > Time.now &&
        (room&.actual_end_at && room.actual_end_at > Time.now) &&
        channel.available_for_search? &&
        !presenter.user.destroyed? &&
        !presenter.user.deleted
    end

    def update_pg_search_document_now?
      instance_variable_get(:@_new_record_before_last_commit) ||
        saved_change_to_title? ||
        saved_change_to_channel_id? ||
        saved_change_to_presenter_id? ||
        saved_change_to_cancelled_at? ||
        saved_change_to_stopped_at? ||
        saved_change_to_start_at? ||
        saved_change_to_status? ||
        saved_change_to_promo_weight? ||
        saved_change_to_promo_start? ||
        saved_change_to_promo_end?
    end

    def update_pg_search_models
      SessionJobs::UpdatePgSearchModels.perform_async(id)
    end
  end
end
