# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Shared::HasPromoWeight do
  describe '#current_promo_weight' do
    let(:promo_weight) { 99 }
    let(:promo_start) { nil }
    let(:promo_end) { nil }
    let(:model) { build(:user, promo_weight: promo_weight, promo_start: promo_start, promo_end: promo_end) }

    context 'when promo_start and promo_end are valid' do
      let(:promo_start) { 1.day.ago }
      let(:promo_end) { 1.day.from_now }

      it { expect { model.current_promo_weight }.not_to raise_error }

      it { expect(model.current_promo_weight).to eq(promo_weight) }
    end

    context 'when promo_start and promo_end are blank' do
      it { expect { model.current_promo_weight }.not_to raise_error }

      it { expect(model.current_promo_weight).to eq(promo_weight) }
    end

    context 'when promo_start is expired' do
      let(:promo_start) { 1.day.from_now }

      it { expect { model.current_promo_weight }.not_to raise_error }

      it { expect(model.current_promo_weight).to be_zero }
    end

    context 'when promo_end is expired' do
      let(:promo_end) { 1.day.ago }

      it { expect { model.current_promo_weight }.not_to raise_error }

      it { expect(model.current_promo_weight).to be_zero }
    end
  end
end
