# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::DocumentAbility do
  subject(:ability) { described_class.new(current_user) }

  describe 'Guest' do
    let(:current_user) { nil }
    let(:visible_document) { FactoryBot.create(:document, hidden: false) }
    let(:hidden_document) { FactoryBot.create(:document, hidden: true) }

    it { expect(ability).to be_able_to(%i[index show], visible_document) }
    it { expect(ability).not_to be_able_to(%i[index show], hidden_document) }
    it { expect(ability).not_to be_able_to(%i[create update destroy], visible_document) }
    it { expect(ability).not_to be_able_to(%i[create update destroy], hidden_document) }
  end

  describe 'Logged in' do
    let(:current_user) { FactoryBot.create(:user) }

    context 'when user' do
      let(:visible_document) { FactoryBot.create(:document, hidden: false) }
      let(:hidden_document) { FactoryBot.create(:document, hidden: true) }

      it { expect(ability).to be_able_to(%i[index show], visible_document) }
      it { expect(ability).not_to be_able_to(%i[index show], hidden_document) }
      it { expect(ability).not_to be_able_to(%i[create update destroy], visible_document) }
      it { expect(ability).not_to be_able_to(%i[create update destroy], hidden_document) }
    end

    context 'when organization owner' do
      before do
        organization = FactoryBot.create(:organization_with_subscription, user: current_user)
        channel = FactoryBot.create(:approved_channel, organization: organization)
        @document = FactoryBot.create(:document, channel: channel)
      end

      it { expect(ability).to be_able_to(%i[index show], @document) }
      it { expect(ability).to be_able_to(%i[create update destroy], @document) }
    end
  end
end
