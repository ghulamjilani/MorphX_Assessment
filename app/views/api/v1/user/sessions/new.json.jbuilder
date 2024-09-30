# frozen_string_literal: true

envelope json, (@status || 200), (@session.pretty_errors if @session.errors.present?) do
  json.session do
    json.partial! '/api/v1/user/sessions/session', session: @session
  end

  json.channel do
    json.partial! '/api/v1/user/channels/channel_short', channel: @session.channel
  end

  json.presentation_info do
    json.partial! '/api/v1/user/sessions/presentation_info', session: @session
  end

  json.presenter do
    json.partial! '/api/v1/user/users/user_short', user: @session.organizer
  end

  json.channels do
    json.array! @channels do |channel|
      json.id channel.id
      json.title channel.title
      json.logo_url channel.image_gallery_url
      json.slug channel.slug
      json.is_default channel.is_default
    end
  end
  json.feature_parameters do
    json.array! @feature_parameters do |fp|
      json.code fp.plan_feature.code
      json.parameter_type fp.plan_feature.parameter_type
      # if org has subscription with trial service_status then always return 30 min in all other cases -- value
      if fp.plan_feature.code == 'max_session_duration'
        json.value @session.duration_available_max
      else
        json.value fp.value
      end
    end
  end
end
