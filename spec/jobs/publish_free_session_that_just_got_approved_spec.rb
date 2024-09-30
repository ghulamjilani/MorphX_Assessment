# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe PublishFreeSessionThatJustGotApproved do
  let(:session) do
    session = create(:immersive_session)
    session.update!({ status: Session::Statuses::REQUESTED_FREE_SESSION_APPROVED })
    session.update!({ publish_after_requested_free_session_is_satisfied_by_admin: true })
    session
  end

  it { expect(session.valid?).to eq(true) }

  it 'does not fail and runs all just_got_published callbacks' do
    session.update({ title: '' })
    expect(session.valid?).to eq(false)
    session.session_invited_immersive_participantships.create(participant: create(:participant))
    Sidekiq::Testing.inline! { described_class.perform_async(session.id) }
  end
end
