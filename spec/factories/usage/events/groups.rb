# frozen_string_literal: true

FactoryBot.define do
  factory :usage_event_group, class: 'Usage::Event::Group' do
    model_id { Session.order(Arel.sql('RANDOM()')).limit(1).pick(:id) || create(:published_livestream_session).id }
    model_type { 'Session' }
    event_type { ::Usage::Event::Types::ALL.sample }
    start_at { 1.hour.ago.beginning_of_hour }
    end_at { 1.hour.ago.end_of_hour }
    value { rand(1024) }
    channel_id { channel&.id }
    organization_id { organization&.id }
  end

  factory :aa_stub_usage_event_group, parent: :usage_event_group
end
