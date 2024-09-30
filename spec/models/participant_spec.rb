# frozen_string_literal: true
require 'spec_helper'

describe Participant do
  subject { create(:presenter) }

  describe '#invited_to_livestream' do
    let!(:participant) { create(:participant) }
    let!(:session) { create(:livestream_session) }

    it 'works' do
      participant1 = create(:participant)
      expect(participant1.session_invited_livestream_participantships).to be_blank

      session.session_invited_livestream_participantships.create(participant: participant1)

      expect(participant1.reload.session_invited_livestream_participantships.order(created_at: :desc).limit(1).first.session).to eq(session)
    end
  end
end
