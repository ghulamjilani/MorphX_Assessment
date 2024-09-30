# frozen_string_literal: true

FactoryBot.define do
  factory :log_user_event, class: 'Log::UserEvent' do
    data { nil }
    page { nil }
    service { nil }
  end

  factory :aa_stub_log_userevent, parent: :log_user_event
end
