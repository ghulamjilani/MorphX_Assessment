# frozen_string_literal: true

envelope json, (@status || 200), (@user.pretty_errors if @user.errors.present?) do
  if @user.parent_organization_id == current_organization.id
    json.partial! 'user', user: @user
  else
    json.partial! 'api/v1/public/users/user_short', model: @user
  end

  json.organization_membership_id @organization_membership.id if @organization_membership

  json.stream_accounts do
    json.array! @user.ffmpegservice_accounts do |ffmpegservice_account|
      json.partial! 'api/v1/user/ffmpegservice_accounts/ffmpegservice_account', ffmpegservice_account: ffmpegservice_account
    end
  end

  if @user.presenter
    json.presenter do
      json.partial! 'api/v1/organization/presenters/presenter', presenter: @user.presenter
    end
  end
end
