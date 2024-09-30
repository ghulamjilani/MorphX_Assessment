# frozen_string_literal: true

namespace :service_plans do
  desc 'Create Service Plans'
  task create: :environment do
    plan_packages = [
      {
        name: 'Starter',
        description: 'Discover your potential',
        position: 1,
        # transcoding_minutes: 120,
        # streaming_minutes: 120,
        # storage: 500,
        # embed: true,
        # channels_count: 1,
        # multi_room: false,
        # ip_cam: false,
        # interactive: true,
        # mobile_devices: true,
        plans_attributes: [
          {
            active: true,
            amount: 4999,
            currency: 'usd',
            interval: 'month',
            interval_count: 1,
            nickname: 'Starter Month',
            trial_period_days: 7
          },
          {
            active: true,
            amount: 53_999,
            currency: 'usd',
            interval: 'year',
            interval_count: 1,
            nickname: 'Starter Annual',
            trial_period_days: 7
          }
        ]
      },
      {
        name: 'Pro',
        description: 'Start your business',
        position: 2,
        # transcoding_minutes: 120,
        # streaming_minutes: 120,
        # storage: 500,
        # embed: true,
        # channels_count: 3,
        # multi_room: true,
        # ip_cam: true,
        # interactive: true,
        # mobile_devices: true,
        plans_attributes: [
          {
            active: true,
            amount: 14_999,
            currency: 'usd',
            interval: 'month',
            interval_count: 1,
            nickname: 'Pro Month',
            trial_period_days: 7
          },
          {
            active: true,
            amount: 161_999,
            currency: 'usd',
            interval: 'year',
            interval_count: 1,
            nickname: 'Pro Annual',
            trial_period_days: 7
          }
        ]
      },
      {
        name: 'Premium',
        description: 'Grow your business',
        position: 3,
        # transcoding_minutes: 120,
        # streaming_minutes: 120,
        # storage: 500,
        # embed: true,
        # channels_count: 10,
        # multi_room: true,
        # ip_cam: true,
        # interactive: true,
        # mobile_devices: true,
        recommended: true,
        plans_attributes: [
          {
            active: true,
            amount: 24_999,
            currency: 'usd',
            interval: 'month',
            interval_count: 1,
            nickname: 'Premium Month',
            trial_period_days: 7
          },
          {
            active: true,
            amount: 269_999,
            currency: 'usd',
            interval: 'year',
            interval_count: 1,
            nickname: 'Premium Annual',
            trial_period_days: 7
          }
        ]
      }
    ]

    PlanPackage.create(plan_packages)
  end
end
