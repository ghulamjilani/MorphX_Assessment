# frozen_string_literal: true

require 'spec_helper'

describe SessionJobs::WatchersCounterJob do
  let(:room) { create(:livestream_session, start_at: 10.seconds.from_now, pre_time: 15).room }
  let(:count) { 10 }

  before do
    client = double
    allow(PublicLivestreamRoomsChannel).to receive(:client).and_return(client)
    allow(client).to receive(:get).with(PublicLivestreamRoomsChannel.subscribers_count_prefix + room.id.to_s).and_return(count)
  end

  it { expect { described_class.new.perform }.not_to raise_error }

  it 'updates watchers count' do
    expect do
      described_class.new.perform
      room.reload
    end.to change(room, :watchers_count).by(count)
  end
end
