# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::UserAbility do
  let(:ability) { described_class.new(current_user) }

  describe '#email_share(user)' do
    context 'when given not signed in user1 ' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :email_share, User.new }
    end

    context 'when given not signed in user 2' do
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :email_share, User.new }
    end
  end

  describe '#view_adult_content' do
    context 'when 12 years old' do
      let(:current_user) { create(:user, birthdate: 12.years.ago.to_date) }

      it { expect(ability).not_to be_able_to :view_adult_content, current_user }
      it { expect(ability).not_to be_able_to :view_major_content, current_user }
    end

    context 'when 20 years old' do
      let(:current_user) { create(:user, birthdate: (18.years + 1.day).ago.to_date) }

      it { expect(ability).to be_able_to :view_adult_content, current_user }
      it { expect(ability).not_to be_able_to :view_major_content, current_user }
    end

    context 'when 21 years old' do
      let(:current_user) { create(:user, birthdate: (21.years + 1.day).ago.to_date) }

      it { expect(ability).to be_able_to :view_adult_content, current_user }
      it { expect(ability).to be_able_to :view_major_content, current_user }
    end
  end

  describe '#create_1st_channel' do
    context 'when given invited co-presenter' do
      let(:session) do
        create(:immersive_session).tap do |s|
          s.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        end
      end
      let(:current_user) { create(:presenter).user }

      it { expect(ability).to be_able_to :create_1st_channel, current_user }
    end
  end

  describe '#read(user)' do
    context 'when given user himself' do
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :read, current_user }
    end

    context 'when given non-presenter user' do
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :read, create(:user) }
    end

    context 'when given signed in user' do
      let(:current_user) { create(:user) }
      let(:user) { create(:presenter).user }

      it { expect(ability).to be_able_to :read, user }
    end

    context 'when given unsigned in user' do
      let(:current_user) { nil }
      let(:user) { create(:presenter).user }

      it { expect(ability).to be_able_to :read, user }
    end

    context 'when given service_admin in user' do
      let(:current_user) { create(:user_service_admin) }
      let(:user) { create(:user) }

      it { expect(ability).to be_able_to :read, user }
    end
  end

  context 'when service subscriptions disabled' do
    let(:service) { described_class.new(current_user) }

    before do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = false
    end

    describe '#access_wizard' do
      let(:current_user) { create(:user) }

      it { expect(service).to be_able_to :access_wizard_by_business_plan, current_user }
    end
  end

  context 'when service subscriptions enabled' do
    let(:service) { described_class.new(current_user) }

    before do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = true
    end

    after do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = false
    end

    describe '#access_wizard' do
      let(:current_user) { create(:user) }
      let(:subscription) { create(:stripe_service_subscription, user: current_user) }

      it 'without subscription' do
        expect(service).not_to be_able_to :access_wizard_by_business_plan, current_user
      end

      describe 'with subscription' do
        it 'with subscription' do
          subscription
          expect(service).to be_able_to :access_wizard_by_business_plan, current_user
        end
      end
    end
  end
end
