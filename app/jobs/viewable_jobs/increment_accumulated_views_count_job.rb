# frozen_string_literal: true

module ViewableJobs
  class IncrementAccumulatedViewsCountJob < ApplicationJob
    def perform
      uncounted_ids = View.not_counted.pluck :id
      return if uncounted_ids.blank?

      views = View.where(id: uncounted_ids)
      views.update_all(counted_at: Time.now.utc)

      views_counts = views.select('views.viewable_id, views.viewable_type, COUNT(views.*) as views_count')
                          .group(:viewable_type, :viewable_id)

      new_group_names = views.distinct(:group_name).select(:group_name).pluck(:group_name)
      existing_group_names = View.where.not(id: uncounted_ids).where(group_name: new_group_names).distinct(:group_name).select(:group_name).pluck(:group_name)
      unique_views_counts = views.where.not(group_name: existing_group_names).group(:viewable_type, :viewable_id).select(:group_name).distinct(:group_name).count

      @viewable_types = {
        Session: {},
        Video: {},
        Recording: {},
        'Blog::Post': {}
      }.stringify_keys
      @additional_viewable_types = {
        Channel: {},
        Organization: {},
        User: {}
      }.stringify_keys

      # collect and group views_counts and unique_views_count by viewable_type and viewable_id
      views_counts.each do |view|
        @viewable_types[view.viewable_type] ||= {}
        @viewable_types[view.viewable_type][view.viewable_id] ||= { views_count: 0, unique_views_count: 0 }
        @viewable_types[view.viewable_type][view.viewable_id][:views_count] += view.views_count
      end
      unique_views_counts.each do |view, count|
        @viewable_types[view[0]][view[1]][:unique_views_count] += count
      end

      @viewable_types.each do |viewable_type, viewable_ids|
        viewable_type.constantize.transaction do
          viewable_ids.each do |viewable_id, counts|
            next unless (viewable = viewable_type.constantize&.find_by(id: viewable_id))

            views_count = viewable.views_count + counts[:views_count]
            unique_views_count = viewable.unique_views_count + counts[:unique_views_count]
            viewable.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now.utc)

            accumulate_channel_counts(viewable.channel, views_count, unique_views_count)
          end
        end
      end

      @additional_viewable_types.each do |viewable_type, viewable_ids|
        viewable_type.constantize.transaction do
          viewable_ids.each do |viewable_id, counts|
            next unless (viewable = viewable_type.constantize.find_by(id: viewable_id))

            views_count = viewable.views_count + counts[:views_count]
            unique_views_count = viewable.unique_views_count + counts[:unique_views_count]
            viewable.update_columns(views_count: views_count, unique_views_count: unique_views_count, updated_at: Time.now.utc)
          end
        end
      end

      schedule_documents_update
    end

    def accumulate_channel_counts(channel, views_count, unique_views_count)
      return unless channel

      @additional_viewable_types['Channel'][channel.id] ||= { views_count: 0, unique_views_count: 0 }
      @additional_viewable_types['Channel'][channel.id][:views_count] += views_count
      @additional_viewable_types['Channel'][channel.id][:unique_views_count] += unique_views_count

      @additional_viewable_types['Organization'][channel.organization_id] ||= { views_count: 0, unique_views_count: 0 }
      @additional_viewable_types['Organization'][channel.organization_id][:views_count] += views_count
      @additional_viewable_types['Organization'][channel.organization_id][:unique_views_count] += unique_views_count

      @additional_viewable_types['User'][channel.organization.user_id] ||= { views_count: 0, unique_views_count: 0 }
      @additional_viewable_types['User'][channel.organization.user_id][:views_count] += views_count
      @additional_viewable_types['User'][channel.organization.user_id][:unique_views_count] += unique_views_count
    end

    def schedule_documents_update
      @viewable_types.merge(@additional_viewable_types).each do |viewable_type, viewable_ids|
        next if viewable_type.eql?('Organization') # Organizations aren't available for search

        viewable_ids.each_key do |viewable_id|
          SearchableJobs::UpdatePgSearchDocumentJob.perform_async(viewable_type, viewable_id)
        end
      end
    end
  end
end
