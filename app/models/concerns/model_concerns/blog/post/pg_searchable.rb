# frozen_string_literal: true

module ModelConcerns::Blog::Post::PgSearchable
  extend ActiveSupport::Concern
  include ModelConcerns::PgSearchable

  included do
    pg_search_scope :search_by_name,
                    against: [:title],
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
                    additional_attributes: lambda { |post|
                      {
                        user_id: post.user_id,
                        channel_id: post.channel_id,
                        organization_id: post.channel.organization_id,
                        fake: post.is_fake?,
                        title: post.title.prepare_for_search,
                        model_created_at: post.created_at,
                        views_count: post.views_count,
                        status: post.status,
                        published: post.status_published?,
                        listed_at: post.published_at,
                        show_on_home: post.show_on_home,
                        hide_on_home: post.hide_on_home,
                        promo_start: post.promo_start,
                        promo_end: post.promo_end,
                        promo_weight: post.current_promo_weight.to_i
                      }
                    }

    skip_callback :save, :after, :update_pg_search_document

    def fulltext_search_data
      [
        user.public_display_name,
        title,
        body
      ].join(' ').prepare_for_search
    end

    def available_for_search?
      return false if destroyed?
      return false if is_fake?
      return false unless status_published?

      channel.organization.active_subscription_or_split_revenue?
    end

    def update_pg_search_document_now?
      instance_variable_get(:@_new_record_before_last_commit) ||
        saved_change_to_title? ||
        saved_change_to_channel_id? ||
        saved_change_to_hide_author? ||
        saved_change_to_show_on_home? ||
        saved_change_to_published_at? ||
        saved_change_to_status? ||
        saved_change_to_promo_weight? ||
        saved_change_to_promo_start? ||
        saved_change_to_promo_end?
    end
  end
end
