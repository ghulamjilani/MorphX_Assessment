# frozen_string_literal: true

envelope json, (@status || 200), (@user_account.pretty_errors if @user_account.errors.present?) do
  json.user_account do
    json.partial! 'user_account', user_account: @user_account
  end
end
