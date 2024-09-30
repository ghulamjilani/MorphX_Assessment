# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SessionJobs::AssignInvitedUsersJob do
  let(:session) { create(:livestream_session) }
  let(:inviter_user_id) { session.presenter.user_id }
  let(:invited_users_attributes) do
    invited_users_attributes = []
    # states = Session::States::ALL - [Session::States::CO_PRESENTER]
    states = [Session::States::IMMERSIVE, Session::States::LIVESTREAM]
    states.each do |state|
      contact_user = FactoryBot.create(:user)
      invited_users_attributes << {
        email: contact_user.email,
        state: state
      }.symbolize_keys
      invited_users_attributes << {
        email: Forgery(:internet).email_address,
        state: state
      }.symbolize_keys
    end
    invited_users_attributes
  end

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
    SessionInvitedImmersiveParticipantship.delete_all
    SessionInvitedLivestreamParticipantship.delete_all
  end

  it 'does not fail' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(session.id, inviter_user_id, invited_users_attributes) } }.not_to raise_error
  end

  it 'creates livestream participantships' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(session.id, inviter_user_id, invited_users_attributes) } }.to change(SessionInvitedLivestreamParticipantship, :count).from(0).to(2)
  end

  it 'creates immersive participantships' do
    expect { Sidekiq::Testing.inline! { described_class.perform_async(session.id, inviter_user_id, invited_users_attributes) } }.to change(SessionInvitedImmersiveParticipantship, :count).from(0).to(2)
  end

  it 'enqueues jobs' do
    expect { described_class.perform_async(session.id, inviter_user_id, invited_users_attributes) }.to change(described_class.jobs, :size)
  end
end
