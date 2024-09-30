# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ApiJobs::RoomTranscoderUptimeJob do
  let(:room) { create(:livestream_room) }

  before do
    # stub webrtcservice response for creating chat channel
    stub_request(:any, /.*webrtcservice.com*/).to_return(status: 200, body: '', headers: {})

    room.update(actual_end_at: 10.minutes.from_now)
  end

  it 'does not fail' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(room.id) } }.not_to raise_error
  end
end
