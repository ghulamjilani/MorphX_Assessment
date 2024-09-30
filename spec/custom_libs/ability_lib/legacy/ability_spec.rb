# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Legacy::Ability do
  let(:ability) { described_class.new(current_user) }

  describe '#share(channel)' do
    context 'when given approved channel' do
      let(:channel) { create(:approved_channel) }
      let(:current_user) { nil }

      it { expect(ability).to be_able_to :share, channel }
    end

    context 'when given non-approved channel' do
      let(:channel) { Channel.new }
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :share, channel }
    end
  end

  describe '#email_share(user)' do
    context 'when given not signed in user1 ' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :email_share, User.new }
    end

    context 'when given not signed in user 2' do
      let(:current_user) { User.new }

      it { expect(ability).to be_able_to :email_share, User.new }
    end
  end

  describe '#receive_session_start_reminders' do
    let(:session) { create(:immersive_session) }

    context 'when paid voluntary participant' do
      let(:participant1) { create(:participant) }
      let(:current_user) { participant1.user }

      before { session.immersive_participants << participant1 }

      it { expect(ability).to be_able_to :receive_session_start_reminders, session }
    end

    context 'when pending invited participant' do
      let(:participant1) { create(:participant) }
      let(:current_user) { participant1.user }

      before { session.session_invited_immersive_participantships.create(participant: participant1) }

      it { expect(ability).to be_able_to :receive_session_start_reminders, session }
    end

    context 'when invited participant who rejected invitation' do
      let(:participant1) { create(:participant) }
      let(:current_user) { participant1.user }

      before do
        create(:rejected_session_invited_immersive_participantship, session: session, participant: participant1)
      end

      it { expect(ability).not_to be_able_to :receive_session_start_reminders, session }
    end

    context 'when invited co presenter who rejected invitation' do
      let(:presenter1) { create(:presenter) }
      let(:current_user) { presenter1.user }

      before { create(:rejected_session_invited_immersive_co_presentership, session: session, presenter: presenter1) }

      it { expect(ability).not_to be_able_to :receive_session_start_reminders, session }
    end

    context 'when paid co-presenter' do
      let(:presenter1) { create(:presenter) }
      let(:current_user) { presenter1.user }

      before { session.co_presenters << presenter1 }

      it { expect(ability).to be_able_to :receive_session_start_reminders, session }
    end

    context 'when primary presenter' do
      let(:current_user) { session.organizer }

      it { expect(ability).to be_able_to :receive_session_start_reminders, session }
    end

    context 'when random user' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :receive_session_start_reminders, session }
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
end
