# frozen_string_literal: true
require 'spec_helper'

describe Presenter do
  describe '#has_enough_credit?(charge_amount)' do
    subject { presenter.has_enough_credit?(charge_amount) }

    context 'when given new presenter with intact initial system credit($100)' do
      let(:presenter) { create(:presenter) }

      before do
        expect(presenter.issued_presenter_credits.count).to eq(0)
      end

      context 'when charge_amount is 9' do
        let(:charge_amount) { 9 }

        it { is_expected.to be true }
      end
    end

    context 'when presenter has expired $90 of his initial $100 free system credit' do
      let(:presenter) { create(:presenter) }

      it 'allows <10$ spending' do
        expect(presenter.issued_presenter_credits.count).to eq(0)

        presenter.presenter_credit_entries.create!(
          amount: 90,
          description: 'Fake spending to make test pass'
        )

        expect(presenter.has_enough_credit?(9)).to be true
        expect(presenter.has_enough_credit?(11)).to be false
      end
    end
  end

  describe '#primary_presenter?(session)' do
    let!(:session) { create(:immersive_session) }

    it 'works' do
      presenter = session.organizer.presenter

      expect(presenter.primary_presenter?(session)).to be true

      expect(create(:presenter).primary_presenter?(session)).to be false
    end
  end

  describe '#co_presenter?(session)' do
    let!(:session) { create(:immersive_session) }

    it 'works' do
      presenter1 = create(:presenter)
      session.co_presenters << presenter1

      expect(presenter1.co_presenter?(session)).to be true

      expect(create(:presenter).co_presenter?(session)).to be false

      expect(session.presenter.co_presenter?(session)).to be false
    end
  end
end
