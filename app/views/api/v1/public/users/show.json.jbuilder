# frozen_string_literal: true

envelope json, (@status || 200), (@user.pretty_errors if @user.errors.present?) do
  json.user do
    json.partial! 'user', model: @user

    json.user_language          format_lang(@user.language)
    json.count_user_followers   @user.count_user_followers
    json.following_users_count @user.following_users_count

    json.organization do
      json.id      @user.organization&.id
      json.url     @user.organization&.absolute_path
      json.name    @user.organization&.name
    end
  end

  json.user_account do
    json.partial! 'api/v1/public/user_accounts/user_account', user_account: @user.user_account

    if @user.user_account
      json.social_links do
        json.array! @user.user_account.social_links do |social_link|
          json.social_link do
            json.partial! 'api/v1/public/social_links/social_link', social_link: social_link
          end
        end
      end
    end
  end

  json.owned_channels do
    json.array! @user.owned_channels do |channel|
      json.channel do
        json.partial! 'api/v1/public/channels/channel', model: channel
      end
    end
  end
end
