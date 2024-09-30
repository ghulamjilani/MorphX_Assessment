# frozen_string_literal: true

require 'spec_helper'

describe SharedSessionLiveImmerssButtonPresenter do
  context 'when given free trial immersive session' do
    context 'when signed in user' do
      let(:session) { create(:free_trial_immersive_session) }
      let(:user) { create(:participant).user }
      let(:ability) do
        AbilityLib::Legacy::Ability.new(user).tap do |ab|
          ab.merge(::AbilityLib::Legacy::AccountingAbility.new(user))
          ab.merge(::AbilityLib::Legacy::NonAdminCrudAbility.new(user))
        end
      end

      it 'does not fail' do
        result = described_class.new(session, user, ability).to_s
        expect(result).to include('Immersive')
      end
    end

    context 'when not signed in user' do
      let(:session) { create(:free_trial_immersive_session) }
      let(:user) { nil }
      let(:ability) do
        AbilityLib::Legacy::Ability.new(user).tap do |ab|
          ab.merge(::AbilityLib::Legacy::AccountingAbility.new(user))
          ab.merge(::AbilityLib::Legacy::NonAdminCrudAbility.new(user))
        end
      end

      it 'does not fail' do
        result = described_class.new(session, nil, ability).to_s
        expect(result).to include('Immersive')
      end
    end
  end
end
