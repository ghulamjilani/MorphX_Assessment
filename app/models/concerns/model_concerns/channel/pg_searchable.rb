# frozen_string_literal: true

module ModelConcerns::Channel::PgSearchable
  extend ActiveSupport::Concern
  include ModelConcerns::PgSearchable

  included do
    after_commit :update_pg_search_models, if: proc { |channel|
      channel.saved_change_to_title? ||
        channel.saved_change_to_description? ||
        channel.saved_change_to_channel_type_id? ||
        channel.saved_change_to_archived_at? ||
        channel.saved_change_to_listed_at? ||
        channel.saved_change_to_status? ||
        channel.saved_change_to_fake?
    }

    pg_search_scope :search_by_name,
                    against: %i[title description],
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
                    additional_attributes: lambda { |channel|
                      {
                        archived: channel.archived?,
                        category_id: channel.category_id,
                        channel_type_id: channel.channel_type_id,
                        fake: channel.fake,
                        listed_at: channel.listed_at,
                        model_created_at: channel.created_at,
                        organization_id: channel.organization_id,
                        popularity: (channel.average ? channel.average.avg : 0),
                        presenter_id: channel.presenter_id,
                        private: channel.listed_at.blank?,
                        show_on_home: channel.show_on_home,
                        hide_on_home: channel.hide_on_home,
                        status: channel.status,
                        title: channel.title.prepare_for_search,
                        user_id: begin
                          (channel.organizer ? channel.organizer.id : channel.presenter.user_id)
                        rescue StandardError
                          -1
                        end,
                        views_count: channel.views_count,
                        promo_start: channel.promo_start,
                        promo_end: channel.promo_end,
                        promo_weight: channel.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    def fulltext_search_data
      us_variants = [
        'united states',
        'united states of america',
        'USA',
        'U.S.',
        'US',
        'U.S.A.'
      ]

      [
        title,
        description,
        begin
          (organizer ? (organizer.user_account.try(:us_country?) ? us_variants.join(' ') : organizer.user_account.try(:country)) : '')
        rescue StandardError
          ''
        end,
        (presenter ? presenter.user&.public_display_name : ''),
        users.map { |u| u&.public_display_name || '' }.join(' '),
        (organization ? organization.user&.public_display_name : ''),
        tags.map(&:name).join(' ')
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?

      !is_fake? && approved? && listed? && !archived? && organizer && !organizer&.deleted && organization.active_subscription_or_split_revenue?
    end

    def update_pg_search_models
      ChannelJobs::UpdatePgSearchModels.perform_async(id)
    end
  end
end
