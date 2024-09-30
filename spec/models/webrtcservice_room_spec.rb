# frozen_string_literal: true
require 'spec_helper'

describe WebrtcserviceRoom do
  let(:room_member_participant) { create(:room_member_participant) }
  let(:room_member_presenter) { create(:room_member_presenter, room: room) }
  let(:room) { room_member_participant.room }
  let(:webrtcservice_room) { create(:webrtcservice_room, session: room.abstract_session) }
  let(:participants_response) do
    {
      participants: [
        {
          'status': 'disconnected',
          'date_updated': '2021-04-15T14:52:33Z',
          'start_time': '2021-04-15T14:52:27Z',
          'account_sid': 'AC2df6e5baadb9e338f6f0487bcb379f67',
          'duration': 6,
          'url': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6c',
          'end_time': '2021-04-15T14:52:33Z',
          'sid': 'PAddac99284e0a6d83ee58b5d8bec3bd6c',
          'room_sid': 'RMc3e5e85a641a53c05fae5a55d6c8285b',
          'date_created': '2021-04-15T14:52:27Z',
          'identity': "{\"id\":#{room_member_presenter.abstract_user_id},\"mid\":#{room_member_presenter.id},\"rl\":\"P\"}",
          'links': {
            'subscribed_tracks': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6c/SubscribedTracks',
            'published_tracks': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6c/PublishedTracks',
            'subscribe_rules': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6c/SubscribeRules'
          }
        },
        {
          'status': 'disconnected',
          'date_updated': '2021-04-15T14:52:33Z',
          'start_time': '2021-04-15T14:52:27Z',
          'account_sid': 'AC2df6e5baadb9e338f6f0487bcb379f68',
          'duration': 6,
          'url': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6d',
          'end_time': '2021-04-15T14:52:33Z',
          'sid': 'PAddac99284e0a6d83ee58b5d8bec3bd6d',
          'room_sid': 'RMc3e5e85a641a53c05fae5a55d6c8285b',
          'date_created': '2021-04-15T14:52:27Z',
          'identity': "{\"id\":#{room_member_participant.abstract_user_id},\"mid\":#{room_member_participant.id},\"rl\":\"U\"}",
          'links': {
            'subscribed_tracks': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6d/SubscribedTracks',
            'published_tracks': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6d/PublishedTracks',
            'subscribe_rules': 'https://video.webrtcservice.com/v1/Rooms/RMc3e5e85a641a53c05fae5a55d6c8285b/Participants/PAddac99284e0a6d83ee58b5d8bec3bd6d/SubscribeRules'
          }
        }
      ]
    }
  end

  describe '#completed?' do
    let(:webrtcservice_room) { build(:webrtcservice_room, status: ::WebrtcserviceRoom::Statuses::ALL.sample) }

    it { expect { webrtcservice_room.completed? }.not_to raise_error }
  end

  describe '#inprogress?' do
    let(:webrtcservice_room) { build(:webrtcservice_room, status: ::WebrtcserviceRoom::Statuses::ALL.sample) }

    it { expect { webrtcservice_room.inprogress? }.not_to raise_error }
  end

  describe '#service_prefix' do
    let(:webrtcservice_room) { build(:webrtcservice_room) }

    it { expect { webrtcservice_room.service_prefix }.not_to raise_error }
  end

  describe '#env' do
    let(:webrtcservice_room) { build(:webrtcservice_room) }

    it { expect { webrtcservice_room.env }.not_to raise_error }
  end

  describe '#decode_name' do
    let(:webrtcservice_room) { create(:webrtcservice_room) }

    it { expect { webrtcservice_room.decode_name }.not_to raise_error }

    it { expect(webrtcservice_room.decode_name).to be_present }
  end

  describe '#generate_unique_name' do
    let(:webrtcservice_room) { create(:webrtcservice_room) }

    it { expect { webrtcservice_room.generate_unique_name }.not_to raise_error }
  end
end
