# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::StopNoPresenterSession do
  let(:room) { webrtcservice_room.room }
  let(:webrtcservice_room) { create(:webrtcservice_room) }

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  it 'does not fail' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(room.id) } }.not_to raise_error
  end

  it 'enqueues jobs' do
    expect { described_class.perform_async(room.id) }.to change(described_class.jobs, :size)
  end
end
