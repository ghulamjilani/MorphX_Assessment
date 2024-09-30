# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe InvalidateNearestUpcomingAbstractSessionCache do
  let(:session) do
    session = create(:immersive_session)
    session.immersive_participants << create(:participant)
    session.livestreamers.create!(participant: create(:participant))
    session
  end

  before do
    stub_request(:any, /.*webrtcservice.com*/)
      .to_return(status: 200, body: '', headers: {})
  end

  it 'does not fail for sessions' do
    Sidekiq::Testing.inline! do
      described_class.perform_async(session.class.to_s, session.id)
    end
  end
end
