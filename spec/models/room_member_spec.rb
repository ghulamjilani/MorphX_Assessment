# frozen_string_literal: true
require 'spec_helper'

describe RoomMember do
  describe 'pinned!' do
    let(:room_member) { create(:room_member) }

    it { expect { room_member.pinned! }.to change(room_member, :pinned).to(true) }
  end

  describe 'unpinned!' do
    let(:room_member) { create(:room_member, pinned: true) }

    it { expect { room_member.unpinned! }.to change(room_member, :pinned).to(false) }
  end
end
