# frozen_string_literal: true

FactoryBot.define do
  factory :webrtcservice_room, class: 'WebrtcserviceRoom' do
    session { create(:published_session, service_type: 'webrtcservice') }
    sid { "RM#{SecureRandom.hex(16)}" }
  end

  factory :aa_stub_webrtcservice_rooms, parent: :webrtcservice_room
end
