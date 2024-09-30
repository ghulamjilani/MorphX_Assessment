# frozen_string_literal: true

require 'spec_helper'

describe Control::Room do
  let(:room_member_participant) { create(:room_member_participant) }
  let(:room_member_banned) { create(:room_member_banned, room: room) }
  let(:room_member_presenter) { create(:room_member_presenter, room: room, abstract_user: room.presenter_user) }
  let(:room_member_co_presenter) { create(:room_member_co_presenter, room: room) }
  let(:ban_reason) { create(:ban_reason) }
  let(:room) { create(:room) }
  let(:control) { described_class.new(room) }

  describe '#start' do
    let(:described_subject) { control.start }

    it { expect { described_subject }.not_to raise_error }
    it { expect(described_subject).to be_truthy }
  end

  describe '#stop' do
    let(:described_subject) { control.stop }

    it { expect { described_subject }.not_to raise_error }
    it { expect(described_subject).to be_truthy }
  end

  describe '#start_record' do
    let(:described_subject) { control.start_record }

    it { expect { described_subject }.not_to raise_error }
  end

  describe '#pause_record' do
    let(:described_subject) { control.pause_record }

    it { expect { described_subject }.not_to raise_error }
    it { expect(described_subject).to be_truthy }
  end

  describe '#resume_record' do
    let(:described_subject) { control.resume_record }

    it { expect { described_subject }.not_to raise_error }
    it { expect(described_subject).to be_truthy }
  end

  describe '#stop_record' do
    let(:described_subject) { control.stop_record }

    it { expect { described_subject }.not_to raise_error }
    it { expect(described_subject).to be_truthy }
  end

  describe '#delete_streams' do
    let(:described_subject) { control.delete_streams }

    it { expect { described_subject }.not_to raise_error }
  end

  describe '#allow_control' do
    it { expect { control.allow_control(room_member_co_presenter.id) }.not_to raise_error }
  end

  describe '#disable_control' do
    it { expect { control.disable_control(room_member_co_presenter.id) }.not_to raise_error }
  end

  describe '#mute' do
    let(:room) { room_member_participant.room }

    it { expect { control.mute(room_member_participant.id) }.not_to raise_error }
  end

  describe '#unmute' do
    let(:room) { room_member_participant.room }

    it { expect { control.unmute(room_member_participant.id) }.not_to raise_error }
  end

  describe '#mute_all' do
    it { expect { control.mute_all }.not_to raise_error }
  end

  describe '#unmute_all' do
    it { expect { control.unmute_all }.not_to raise_error }
  end

  describe '#start_video' do
    let(:room) { room_member_participant.room }

    it { expect { control.start_video(room_member_participant.id) }.not_to raise_error }
  end

  describe '#stop_video' do
    let(:room) { room_member_participant.room }

    it { expect { control.stop_video(room_member_participant.id) }.not_to raise_error }
  end

  describe '#start_all_videos' do
    it { expect { control.start_all_videos }.not_to raise_error }
  end

  describe '#stop_all_videos' do
    it { expect { control.stop_all_videos }.not_to raise_error }
  end

  describe '#enable_backstage' do
    let(:room) { room_member_participant.room }

    it { expect { control.enable_backstage(room_member_participant.id) }.not_to raise_error }
  end

  describe '#disable_backstage' do
    let(:room) { room_member_participant.room }

    it { expect { control.disable_backstage(room_member_participant.id) }.not_to raise_error }
  end

  describe '#enable_all_backstage' do
    it { expect { control.enable_all_backstage }.not_to raise_error }
  end

  describe '#disable_all_backstage' do
    it { expect { control.disable_all_backstage }.not_to raise_error }
  end

  describe '#ban_kick' do
    context 'when user is banned for the first time' do
      it { expect { control.ban_kick(room_member_participant.id, ban_reason.id) }.not_to raise_error }
    end

    context 'when user is already banned' do
      it { expect { control.ban_kick(room_member_banned.id, ban_reason.id) }.not_to raise_error }
    end
  end

  describe '#unban' do
    it { expect { control.unban(room_member_banned.id) }.not_to raise_error }
  end

  describe '#pin' do
    let(:room) { room_member_participant.room }

    it { expect { control.pin(room_member_participant.id) }.not_to(raise_error) }

    it 'pins user' do
      expect do
        control.pin(room_member_participant.id)
        room_member_participant.reload
      end.to change(room_member_participant, :pinned).to(true)
    end
  end

  describe '#pin_only' do
    let(:room) { room_member_participant.room }

    it { expect { control.pin_only(room_member_participant.id) }.not_to(raise_error) }

    it 'pins user' do
      expect do
        control.pin_only(room_member_participant.id)
        room_member_participant.reload
      end.to change(room_member_participant, :pinned).to(true)
    end
  end

  describe '#unpin' do
    let(:room) { room_member_participant.room }
    let(:room_member_participant) { create(:room_member_participant, pinned: true) }

    it { expect { control.unpin(room_member_participant.id) }.not_to(raise_error) }

    it 'unpins user' do
      expect do
        control.unpin(room_member_participant.id)
        room_member_participant.reload
      end.to change(room_member_participant, :pinned).to(false)
    end
  end

  describe '#unpin_all' do
    let(:room) { room_member_participant.room }
    let(:room_member_participant) { create(:room_member_participant, pinned: true) }

    it { expect { control.unpin_all }.not_to(raise_error) }

    it 'unpins users' do
      expect do
        control.unpin_all
        room_member_participant.reload
      end.to change(room_member_participant, :pinned).to(false)
    end
  end

  describe '#toggle_share' do
    it { expect { control.toggle_share }.not_to(raise_error) }

    it 'toggles screen share' do
      expect do
        control.toggle_share
        room.reload
      end.to change(room, :is_screen_share_available)
    end
  end
end
