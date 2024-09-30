# frozen_string_literal: true

envelope json do
  json.cache! @organization, expires_in: 1.day do
    json.organization do
      json.extract! @organization, :id, :name
      json.logo_url asset_url(@organization.logo_url)
      json.rating   @organization.average&.avg || 0.0
      json.voted    @organization.raters_quantity
    end
  end

  json.cache! @creators_subscription, expires_in: 1.day do
    json.current_plan do
      if @creators_subscription&.stripe_plan&.plan_package.present?
        json.name               @creators_subscription.stripe_plan.plan_package.name
        json.streaming_time     @creators_subscription.stripe_plan.plan_package.streaming_time
        json.transcoding_time   @creators_subscription.stripe_plan.plan_package.transcoding_time
        json.storage            @creators_subscription.stripe_plan.plan_package.storage
        json.max_channels_count @creators_subscription.stripe_plan.plan_package.max_channels_count
      else
        json.name 'Free'
        json.streaming_time '*'
        json.transcoding_time '*'
        json.storage 15
        json.max_channels_count 0
      end
    end
  end

  json.channels(@channels) do |channel|
    json.cache! [channel], expires_in: 1.day do
      json.name                channel.title
      json.past_sessions_count channel.past_sessions_count
      json.replays_count       channel.replays.count
      json.recordings_count    channel.recordings.count
      json.url                 channel.absolute_path
      json.cover_url           asset_url(channel.image_tile_url)

      json.creators(channel.channel_invited_presenterships.accepted) do |creator|
        json.name     creator.presenter.user.public_display_name
        json.url      creator.presenter.user.absolute_path
        json.logo_url asset_url(creator.presenter.avatar_url)
      end
    end
  end

  json.statistics do
    json.channels_count       @channels.count
    json.past_sessions_count  @channels.inject(0) { |sum, channel| sum + channel.past_sessions_count }
    json.sessions_minutes     @channels.inject(0) { |sum, channel| sum + channel.sessions.inject(0) { |s, session| s + session.duration } }
    json.replays_count      @channels.inject(0) { |sum, channel| sum + channel.videos.count }
    json.replays_storage    @channels.inject(0) { |sum, channel| sum + channel.videos_storage_size }
    json.recording_count    @channels.inject(0) { |sum, channel| sum + channel.recordings.count }
    json.recordings_storage @channels.inject(0) { |sum, channel| sum + channel.recordings_storage_size }
    json.creators_count     @channels.inject(0) { |sum, channel| sum + channel.channel_invited_presenterships.accepted.count }
    json.used_storage 15_400
    json.used_streaming_seconds @channels.inject(0) { |sum, channel| sum + channel.sessions.inject(0) { |s, session| s + session.duration } } * 60
    json.used_transcoding_seconds 3203
  end
end
