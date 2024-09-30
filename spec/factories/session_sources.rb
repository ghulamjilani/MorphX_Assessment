# frozen_string_literal: true
FactoryBot.define do
  factory :session_source do
    association :session, factory: :immersive_session
    name { 'MyString' }
  end
end
