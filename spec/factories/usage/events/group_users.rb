# frozen_string_literal: true

FactoryBot.define do
  factory :usage_event_group_user, class: 'Usage::Event::GroupUser' do
    client_type { ::Usage::Client::Types::ALL.sample }
    ip { Forgery(:internet).ip_v4 }
    last_resolution { '1920x1080' }
    user_agent { 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36' }
    user_id { User.order(Arel.sql('RANDOM()')).limit(1).pick(:id) || create(:user).id }
    value { rand(1024) }
    visitor_id { SecureRandom.uuid }
    association :events_group, factory: :usage_event_group
  end

  factory :aa_stub_usage_event_groupuser, parent: :usage_event_group_user
end
