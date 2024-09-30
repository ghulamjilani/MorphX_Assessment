# frozen_string_literal: true

FactoryBot.define do
  factory :room do
    association :abstract_session, factory: :immersive_session
    status { Room::Statuses::ACTIVE }
    actual_start_at { Time.zone.now }
    actual_end_at   { Time.zone.now }
    vod_is_fully_ready { true }
    after(:build) do |room|
      room.presenter_user = room.abstract_session.organizer
      # session factory creates its own room via callback before this room is created
      Room.where(abstract_session_id: room.abstract_session_id).where.not(id: room.id).find_each(&:destroy)
    end
  end

  factory :room_on_listed_channel, parent: :room do
    association :abstract_session, factory: :immersive_session_on_listed_channel
  end

  factory :immersive_room, parent: :room_on_listed_channel do
    association :abstract_session, factory: :immersive_session_on_listed_channel
  end

  factory :livestream_room, parent: :room do
    service_type { Room::ServiceTypes::RTMP }
    association :abstract_session, factory: :livestream_session
  end

  factory :room_with_replay, parent: :room_on_listed_channel do
    association :abstract_session, factory: :recorded_session
  end

  factory :immersive_room_active, parent: :immersive_room do
    association :abstract_session, factory: :published_session
    after(:create) do |room|
      start_at = 5.minutes.ago
      end_at = 10.minutes.from_now
      room.abstract_session.update_columns(start_at: start_at)
      room.update_columns(actual_start_at: start_at, actual_end_at: end_at)
    end
  end

  factory :immersive_room_closed, parent: :immersive_room do
    actual_start_at { 60.minutes.ago }
    actual_end_at   { 30.minutes.ago }
    status          { Room::Statuses::CLOSED }
    association :abstract_session, factory: :published_session
  end

  factory :aa_stub_rooms, parent: :room
end
