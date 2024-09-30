# frozen_string_literal: true
require 'spec_helper'

describe SessionCoPresentership do
  describe 'validations' do
    let(:session) { create(:immersive_session) }
    let(:primary_presenter) { session.presenter }

    context 'when already primary presenter of the session' do
      it 'could not be co-presenter' do
        expect { session.co_presenters << primary_presenter }.to raise_error(/already primary presenter/)
      end
    end

    context 'when invited participant to the session' do
      let(:user) { create(:user) }

      before do
        create(:participant, user: user)
        create(:presenter, user: user)

        session.session_invited_immersive_participantships.create(participant: user.participant)
      end

      it 'could not be co-presenter at the same time' do
        expect do
          session.co_presenters << user.presenter
        end.to raise_error(/already invited to the session as immersive participant/)
      end
    end
  end
end
