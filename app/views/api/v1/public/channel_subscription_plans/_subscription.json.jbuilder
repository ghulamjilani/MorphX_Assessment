# frozen_string_literal: true

json.extract! model, :id, :description
json.can_be_subscribed current_ability.can?(:monetize_content_by_business_plan, model.channel.organization)
