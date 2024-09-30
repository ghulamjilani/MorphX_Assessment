# frozen_string_literal: true

module ModelConcerns::Shared::Viewable
  extend ActiveSupport::Concern

  included do
    has_many :views, as: :viewable, dependent: :delete_all

    def viewable?
      respond_to?(:views_count) && respond_to?(:unique_views_count)
    end

    def unique_view_exists?(user_id_or_ip, options = {})
      query = views
      if options[:exclude]
        query = query.where.not(id: options[:exclude])
      end

      query.exists?(group_name: unique_view_group_name(user_id_or_ip))
    end

    def unique_view_group_start_at
      Time.now.utc.beginning_of_day
    end

    def unique_view_group_name(user_id_or_ip)
      "#{self.class.name}|#{id}|#{user_id_or_ip}|#{unique_view_group_start_at}"
    end

    def count_unique_views
      views.distinct.count(:group_name)
    end
  end
end
