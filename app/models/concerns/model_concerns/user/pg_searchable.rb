# frozen_string_literal: true

module ModelConcerns::User::PgSearchable
  extend ActiveSupport::Concern
  include ModelConcerns::PgSearchable

  included do
    pg_search_scope :search_by_name,
                    against: %i[first_name last_name display_name],
                    associated_against: {
                      user_account: %i[
                        bio
                        tagline
                      ]
                    },
                    using: {
                      trigram: {
                        threshold: 0.1
                      },
                      tsearch: {
                        dictionary: 'english',
                        prefix: true,
                        negation: true
                      }
                    }

    multisearchable against: [:fulltext_search_data],
                    if: :available_for_search?,
                    additional_attributes: lambda { |user|
                      {
                        user_id: user.id,
                        presenter_id: user.presenter.try(:id),
                        organization_id: user.organization.try(:id),
                        valid_channels_count: user.channels.approved.listed.not_archived.count,
                        popularity: user.average(Session::RateKeys::QUALITY_OF_CONTENT) ? user.average(Session::RateKeys::QUALITY_OF_CONTENT).avg : 0,
                        fake: user.fake,
                        private: user.fake,
                        title: user.public_display_name.prepare_for_search,
                        show_on_home: user.show_on_home,
                        hide_on_home: user.hide_on_home,
                        model_created_at: user.created_at,
                        listed_at: user.created_at,
                        views_count: user.views_count,
                        promo_start: user.promo_start,
                        promo_end: user.promo_end,
                        promo_weight: user.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    after_commit :update_pg_search_models, if: proc { |user|
      user.saved_change_to_first_name? ||
        user.saved_change_to_last_name? ||
        user.saved_change_to_display_name? ||
        user.saved_change_to_fake? ||
        user.saved_change_to_deleted?
    }

    def fulltext_search_data
      [
        first_name,
        last_name,
        display_name,
        user_account.try(:bio),
        user_account.try(:tagline),
        user_account.try(:talent_list)
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?

      !fake && !deleted && all_channels_with_credentials(:start_session).filter { |channel| channel.organization.active_subscription_or_split_revenue? }.present?
    end

    def update_pg_search_models
      UserJobs::UpdatePgSearchModels.perform_async(id)
    end
  end
end
