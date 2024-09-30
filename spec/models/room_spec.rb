# frozen_string_literal: true
require 'spec_helper'

describe Room do
  describe 'validation' do
    before do
      allow_any_instance_of(described_class).to receive(:time_overlap)
    end

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:abstract_session_type) }
  end

  it 'touches abstract session when started' do
    room = create(:room, status: Room::Statuses::AWAITING)
    abstract_session = room.abstract_session
    was_cache_key = abstract_session.cache_key

    expect do
      # simulate #active! method
      expect(room.status).not_to eq(Room::Statuses::ACTIVE)
      room.status = Room::Statuses::ACTIVE
      room.save!
    end.to change(room.reload, :cache_key)

    expect(abstract_session.reload.cache_key).not_to eq(was_cache_key)
  end

  describe 'assign_room' do
    it 'creates a room with the same time as session with lobby' do
      session = FactoryBot.create(:immersive_session)
      expect(session.room).not_to be nil
      expect(session.room.actual_start_at).to eq session.start_at - session.pre_time.minutes
      expect(session.room.actual_end_at).to eq session.end_at
    end

    it 'updates room time' do
      session = FactoryBot.create(:immersive_session, duration: 30)
      immersive_session = FactoryBot.create(:immersive_session, start_at: session.start_at, duration: session.duration)
      immersive_session.start_at = immersive_session.start_at - 15.minutes
      immersive_session.save
      expect(immersive_session).not_to be_new_record
    end

    it 'runs ApiJobs::AutoStartSession' do
      session = FactoryBot.build(:immersive_session, duration: 30, autostart: false)
      expect do
        session.save!
      end.not_to change(ApiJobs::AutoStartSession.jobs, :size)

      session.autostart = true
      session.service_type = Room::ServiceTypes::IPCAM
      session.start_at = session.start_at + 1.second
      expect do
        session.save!
      end.to change(ApiJobs::AutoStartSession.jobs, :size).by(1)

      session.autostart = false
      session.save!
      expect do
        session.save!
      end.not_to change(ApiJobs::AutoStartSession.jobs, :size)
    end
  end

  describe '#cable_pinned_notification' do
    let(:room) { create(:room_member_participant).room }

    it { expect { room.cable_pinned_notification }.not_to raise_error }
  end

  describe '#user_backstage_enabled?' do
    subject { room.user_backstage_enabled?(user) }

    let(:room_member) do
      create(:room_member_participant, room: create(:immersive_room_active, backstage: room_backstage))
    end
    let(:room) { room_member.room }
    let(:user) { room_member.user }

    context 'when room backstage enabled' do
      let(:room_backstage) { true }

      context 'when user backstage enabled' do
        before do
          room_member.backstage_enable!
        end

        it { is_expected.to eq(true) }
      end

      context 'when user backstage disabled' do
        before do
          room_member.backstage_disable!
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when room backstage disabled' do
      let(:room_backstage) { false }

      context 'when user backstage enabled' do
        before do
          room_member.backstage_enable!
        end

        it { is_expected.to eq(false) }
      end

      context 'when user backstage disabled' do
        before do
          room_member.backstage_disable!
        end

        it { is_expected.to eq(false) }
      end
    end
  end
end
