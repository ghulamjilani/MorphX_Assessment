# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::NotifyUnnotifiedInvitedParticipantsJob do
  let(:session) { create(:published_livestream_session) }
  let(:session_invited_immersive_participantship) { create(:session_invited_immersive_participantship, session: session) }
  let(:session_invited_livestream_participantship) { create(:session_invited_livestream_participantship, session: session) }
  let(:mailer) { double }
  let(:message) { double }

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
    session_invited_immersive_participantship
    session_invited_livestream_participantship

    allow(Immerss::SessionMultiFormatMailer).to receive(:new).and_return(mailer)
    allow(mailer).to receive(:participant_invited_to_abstract_session).and_return(message)
    allow(message).to receive(:deliver)

    Sidekiq::Testing.inline! { described_class.perform_async(session.id) }
  end

  it 'does not fail' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(session.id) } }.not_to raise_error
  end

  it 'notifies immersive participants' do
    expect(mailer).to have_received(:participant_invited_to_abstract_session).with(session.id, session_invited_immersive_participantship.participant_id)
  end

  it 'notifies livestream participants' do
    expect(mailer).to have_received(:participant_invited_to_abstract_session).with(session.id, session_invited_livestream_participantship.participant_id)
  end
end
