# frozen_string_literal: true
FactoryBot.define do
  factory :room_member do
    abstract_user { create(:user) }
    association :room, factory: :immersive_room_active
    kind { RoomMember::Kinds::ALL.sample }
    source_id { create(:session_source).id }
    has_control { false }
    mic_disabled { false }
    video_disabled { false }
    display_name { abstract_user.display_name }
  end

  factory :room_member_participant, parent: :room_member do
    kind { RoomMember::Kinds::PARTICIPANT }
  end

  factory :room_member_presenter, parent: :room_member do
    kind { RoomMember::Kinds::PRESENTER }
    has_control { true }
  end

  factory :room_member_co_presenter, parent: :room_member_presenter do
    kind { RoomMember::Kinds::CO_PRESENTER }
  end

  factory :room_member_banned, parent: :room_member_participant do
    banned { true }
    association :ban_reason, factory: :ban_reason
  end

  factory :room_member_guest, parent: :room_member_participant do
    abstract_user { create(:guest) }
    display_name { abstract_user.public_display_name }
  end

  factory :room_member_guest_banned, parent: :room_member_guest do
    banned { true }
    association :ban_reason, factory: :ban_reason
  end

  factory :aa_stub_room_members, parent: :room_member
end
