# frozen_string_literal: true

envelope json do
  json.id                       @user.id
  json.avatar_url               @user.avatar_url
  json.public_display_name      @user.public_display_name
  json.rating                   numeric_rating_for(@user)
  json.raters_count             @user.raters_count
  json.can_follow               !current_user.fast_following?(@user)
  json.can_contact              can?(:contact, @user)

  json.socials do
    json.facebook_url           @facebook_social_link&.link_as_url
    json.twitter_url            @twitter_social_link&.link_as_url
    json.instagram_url          @instagram_social_link&.link_as_url
    json.linkedin_url           @linkedin_social_link&.link_as_url
    json.youtube_url            @youtube_social_link&.link_as_url
    json.telegram_url           @telegram_social_link&.link_as_url
    json.website_url            @website_url&.link_as_url
  end

  json.user_account do
    ua = @user.account
    json.bio                    ua&.bio
    json.country                ua&.country || 'US'
  end
  json.user_language            format_lang(@user.language)
  json.website_url              @website_url
  json.count_user_followers     @user.count_user_followers
  json.following_users_count    @user.following_users_count
  json.organization do
    org = @user.organization
    json.id                     org&.id
    json.url                    org&.absolute_path
    json.name                   org&.name
  end
  json.channels do
    json.array! @owned_channels do |channel|
      json.id                   channel.id
      json.title                channel.title
      json.description          channel.description
      json.tagline              channel.tagline
      json.logo_url             channel.logo_url
      json.image_url            channel.image_mobile_preview_url
      json.absolute_path        channel.absolute_path
      json.presenters do
        json.array! channel.users do |presenter|
          json.id         presenter.id
          json.avatar     presenter.small_avatar_url
          json.full_name  presenter.full_name
        end
      end
    end
  end
end
