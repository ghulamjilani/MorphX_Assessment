# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::StopNoPresenterNotificationJob do
  let(:room) { create(:room) }

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  it 'does not fail' do
    SessionJobs::StopNoPresenterSession.perform_at(5.minutes, room.id)
    expect { Sidekiq::Testing.inline! { described_class.perform_async(room.id) } }.not_to raise_error
  end
end
