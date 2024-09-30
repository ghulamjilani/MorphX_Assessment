# frozen_string_literal: true
FactoryBot.define do
  factory :auth_user_token, class: 'Auth::UserToken' do
    user
  end
end
