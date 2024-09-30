# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe CheckVodAbstractSessionEventualAvailability do
  let(:session) { create(:immersive_session_with_recorded_delivery) }

  it 'does not fail for sessions' do
    create(:room_member, room: session.room, joined: true)
    mailer = double
    allow(mailer).to receive(:deliver_now)
    allow(Mailer).to receive(:vod_didnt_became_available_on_time).once.with(session).and_return(mailer)
    Sidekiq::Testing.inline! { described_class.perform_async(session.class.to_s, session.id) }
  end
end
