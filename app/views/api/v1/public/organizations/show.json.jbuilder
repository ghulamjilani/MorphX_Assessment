# frozen_string_literal: true

envelope json, (@status || 200), (@organization.pretty_errors if @organization.errors.present?) do
  json.organization do
    json.partial! 'organization', model: @organization
    json.user do
      json.extract! @organization.user, :id, :public_display_name, :relative_path, :avatar_url
      json.has_booking_slots @organization.user.has_booking_slots?
    end
    json.following @following
    json.channels do
      json.array! @owned_channels do |channel|
        json.partial! 'api/v1/public/channels/channel', model: channel
      end
    end
    json.subscription_features do
      json.can_manage_blog current_ability.can?(:manage_blog_by_business_plan, @organization)
      json.can_manage_creators current_ability.can?(:manage_creators_by_business_plan, @organization)
      json.can_manage_admins current_ability.can?(:manage_admins_by_business_plan, @organization)
      json.can_create_channel current_ability.can?(:create_channel_by_business_plan, @organization)
    end
    json.default_location organization_default_user_path(@organization)
  end
end
