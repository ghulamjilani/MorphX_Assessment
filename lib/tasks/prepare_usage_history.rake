# frozen_string_literal: true

namespace :usage do
  task :prepare_history, [:ids] => :environment do |_task, _args|
    plan_feature = PlanFeature.find_by!(code: :storage)
    Video.where.not(size: [0, nil]).find_each do |video|
      feature_usage = FeatureUsage.find_or_create_by(organization_id: video.organization_id, plan_feature:)

      if feature_usage.allocated_usage_bytes.zero? && video.channel.organization.user.service_subscription.present?
        allocated_usage_bytes = video.channel.organization.user.service_subscription.feature_value(:storage)
        feature_usage.update(allocated_usage_bytes:)
      end

      video.change_storage_usage(
        video.size.to_i,
        {
          action_name: 'prepare history',
          created_at: video.created_at
        }
      )
    rescue StandardError => e
      puts ['Video', video.id, e.message]
    end

    Recording.where.not(size: [0, nil]).find_each do |recording|
      feature_usage = FeatureUsage.find_or_create_by(organization_id: recording.organization_id, plan_feature:)

      if feature_usage.allocated_usage_bytes.zero? && recording.channel.organization.user.service_subscription.present?
        allocated_usage_bytes = recording.channel.organization.user.service_subscription.feature_value(:storage)
        feature_usage.update(allocated_usage_bytes:)
      end

      recording.change_storage_usage(
        recording.size.to_i,
        {
          action_name: 'prepare history',
          created_at: recording.created_at
        }
      )
    rescue StandardError => e
      puts ['Recording', recording.id, e.message]
    end
  end
end
