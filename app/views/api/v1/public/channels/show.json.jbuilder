# frozen_string_literal: true

envelope json, (@status || 200), (@channel.pretty_errors if @channel.errors.present?) do
  json.channel do
    json.partial! 'channel', model: @channel
    json.can_create_post current_ability.can?(:manage_blog_post, @channel)
    json.can_purchase_content current_ability.can?(:monetize_content_by_business_plan, @channel.organization)
    json.show_reviews @channel.show_reviews

    if @channel.subscription.present?
      json.subscription do
        json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: @channel.subscription
        json.plans do
          json.array! @channel.subscription.plans.active.order(amount: :asc) do |plan|
            json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
          end
        end
      end
    end

    json.live_now @channel.live_session_exists?
  end

  json.organizer do
    json.partial! '/api/v1/user/users/user_short', user: @channel.organizer
  end

  if @channel.polls.enabled.first.present?
    json.poll do
      json.partial! 'api/v1/public/poll/polls/poll', poll: @channel.polls.enabled.first
    end
  end
end
