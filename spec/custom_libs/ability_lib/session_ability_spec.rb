# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::SessionAbility do
  let(:ability) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }

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

  describe '#accept_or_reject_invitation(session)' do
    describe 'participant role' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:published_session) }

      context 'when invited and pending action' do
        before { session.session_invited_immersive_participantships.create(participant: current_user.participant) }

        it { expect(ability).to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already rejected' do
        before do
          create(:rejected_session_invited_immersive_participantship, session: session,
                                                                      participant: current_user.participant)
        end

        it { expect(ability).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already accepted' do
        before do
          create(:accepted_session_invited_immersive_participantship, session: session,
                                                                      participant: current_user.participant)
        end

        it { expect(ability).not_to be_able_to :accept_or_reject_invitation, session }
      end
    end

    describe 'co-presenter role' do
      let(:current_user) { create(:presenter).user }
      let(:session) { create(:immersive_session) }

      context 'when invited and pending action' do
        before { session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter) }

        it { expect(ability).to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already rejected' do
        before do
          create(:rejected_session_invited_immersive_co_presentership, session: session,
                                                                       presenter: current_user.presenter)
        end

        it { expect(ability).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already accepted' do
        before do
          create(:accepted_session_invited_immersive_co_presentership, session: session,
                                                                       presenter: current_user.presenter)
        end

        it { expect(ability).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when given a session with livestream-only delivery method' do
        let(:session) { create(:session_with_livestream_only_delivery) }

        before { session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter) }

        it { expect(ability).to be_able_to :accept_or_reject_invitation, session }
      end
    end
  end

  describe '#obtain_free_trial_livestream_access(session)' do
    context 'when given new free trial session and a new participant' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:session_with_livestream_only_delivery, free_trial_for_first_time_participants: true,
                                                       livestream_free_slots: 2)
      end

      it { expect(ability).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(ability).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given new free trial session and not logged in user' do
      let(:current_user) { nil }
      let(:session) do
        create(:session_with_livestream_only_delivery, free_trial_for_first_time_participants: true,
                                                       livestream_free_slots: 2)
      end

      it { expect(ability).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given free trial session but current_user has already been trial user of another session in this channel' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      before do
        session2 = create(:free_trial_livestream_session, channel: session.channel, presenter: session.presenter)
        create(:livestreamer, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(ability).not_to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given user that already used immersive free trial in similar session' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      before do
        session2 = create(:free_trial_immersive_session, channel: session.channel, presenter: session.presenter)
        create(:session_participation, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(ability).not_to be_able_to :obtain_free_trial_livestream_access, session }
    end
  end

  describe '#obtain_free_trial_immersive_access(session)' do
    context 'when given new free trial session and a new participant' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(ability).to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given new free trial session and not logged in user' do
      let(:current_user) { nil }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(ability).to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given new free trial session and invited co-presenter' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      before do
        create(:presenter, user: current_user)

        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
      end

      it { expect(ability).not_to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given free trial session but current_user has already been trial user of another session in this channel' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      before do
        session2 = create(:free_trial_immersive_session, channel: session.channel, presenter: session.presenter)
        create(:session_participation, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(ability).not_to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(ability).to be_able_to :obtain_free_trial_immersive_access, session }
    end
  end

  describe '#obtain_livestream_access_to_free_session(session)' do
    context 'when given completely free session' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:completely_free_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).to be_able_to :obtain_livestream_access_to_free_session, session }

      context 'when given service_admin' do
        let(:current_user) { create(:user_service_admin) }
        let(:session) { create(:completely_free_session) }

        it { expect(ability).to be_able_to :obtain_livestream_access_to_free_session, session }
      end
    end

    context 'when given completely free session and not logged in user' do
      let(:current_user) { nil }
      let(:session) do
        create(:completely_free_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).to be_able_to :obtain_livestream_access_to_free_session, session }
    end
  end

  describe '#obtain_immersive_access_to_free_session(session)' do
    context 'when given completely free session' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:completely_free_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:immersive_session) }

      it { expect(ability).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given completely free session and not logged in user' do
      let(:current_user) { nil }
      let(:session) do
        create(:completely_free_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given completely free session with livestream-only delivered method and invited co-presenter' do
      let(:current_user) { create(:presenter).user }

      let(:session) do
        session = create(:immersive_session,
                         immersive_purchase_price: nil,
                         immersive_type: nil,
                         max_number_of_immersive_participants: nil,
                         livestream_access_cost: 0,
                         requested_free_session_satisfied_at: Time.zone.now).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end

        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        session
      end

      it { expect(ability).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given completely free session and current_user already as a member of it' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        session = create(:immersive_session, immersive_free: true,
                                             requested_free_session_satisfied_at: Time.zone.now).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
        session.immersive_participants << current_user.participant
        session
      end

      it { expect(ability).not_to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given free trial session' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:free_trial_immersive_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).not_to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given paid session and user without subscription' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:immersive_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(ability).not_to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given paid session and user with subscription' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:immersive_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      before do
        create(:stripe_db_subscription,
               stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: session.channel)),
               user: current_user)
      end

      it { expect(ability).to be_able_to :obtain_immersive_access_to_free_session, session }
    end
  end

  describe '#purchase_livestream_access(session)' do
    context 'when given already paid' do
      let(:session) { create(:session_with_livestream_only_delivery) }

      let(:current_user) { create(:participant).user }

      before do
        session.livestream_participants << current_user.participant
        session.reload
      end

      it { expect(ability).not_to be_able_to :purchase_livestream_access, session }
    end

    context 'when not signed in' do
      let(:current_user) { nil }

      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(ability).to be_able_to :purchase_livestream_access, session }
    end

    context 'when also a free_trial session' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      it { expect(ability).to be_able_to :purchase_livestream_access, session }
    end

    context 'when still can be bought' do
      let(:current_user) { create(:participant).user }

      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(ability).to be_able_to :purchase_livestream_access, session }
    end
  end

  describe '#purchase_immersive_access(session)' do
    context 'when already paid' do
      let(:session) { create(:published_session) }

      let(:current_user) { create(:participant).user }

      before do
        session.immersive_participants << current_user.participant
        session.reload
      end

      it { expect(ability).not_to be_able_to :purchase_immersive_access, session }
    end

    context 'when invited as co-presenter' do
      let(:session) do
        create(:one_on_one_session).tap do |session|
          session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        end
      end

      let(:current_user) { create(:presenter).user }

      it { expect(ability).to be_able_to :purchase_immersive_access, session }
    end

    context 'when not signed in but there are available slots' do
      let(:current_user) { nil }

      let(:session) do
        create(:published_session, min_number_of_immersive_and_livestream_participants: 1,
                                   max_number_of_immersive_participants: 2, private: false)
      end

      it { expect(ability).to be_able_to :purchase_immersive_access, session }
    end

    context 'when group session' do
      context 'when given free trial session' do
        let(:current_user) { create(:participant).user }
        let(:session) { create(:free_trial_immersive_session) }

        it { expect(ability).to be_able_to :purchase_immersive_access, session }
      end

      context 'when public' do
        let(:current_user) { create(:participant).user }

        let(:session1) do
          create(:published_session, min_number_of_immersive_and_livestream_participants: 1,
                                     max_number_of_immersive_participants: 3, private: false)
        end
        let(:session2) do
          create(:published_session, min_number_of_immersive_and_livestream_participants: 1,
                                     max_number_of_immersive_participants: 2, private: false)
        end

        before do
          session1.immersive_participants << create(:participant)
          session1.immersive_participants << create(:participant)
          session1.immersive_participants << create(:participant)
          session2.immersive_participants << create(:participant)
        end

        it { expect(ability).not_to be_able_to :purchase_immersive_access, session1 }
        it { expect(ability).to be_able_to :purchase_immersive_access, session2 }
      end

      context 'when  private' do
        let(:current_user) { create(:participant).user }
        let(:session) { create(:private_published_session) }

        it { expect(ability).not_to be_able_to :purchase_immersive_access, session }

        it do
          session.session_invited_immersive_participantships.create(participant: current_user.participant)
          expect(ability).to be_able_to :purchase_immersive_access, session
        end
      end
    end

    context 'when one-on-one public session' do
      let(:session) { create(:one_on_one_session, private: false) }

      context 'when not invited' do
        before { session.update!({ status: 'published' }) }

        let(:current_user) { create(:user) }

        it('when no one has purchased the slot yet') {
          expect(ability).to be_able_to :purchase_immersive_access, session
        }

        it 'when someone else has bought the slot already' do
          session.immersive_participants << create(:participant)
          expect(ability).not_to be_able_to :purchase_immersive_access, session
        end
      end
    end
  end

  describe '#live_opt_out_and_get_money_refund(session)' do
    let(:current_user) { create(:presenter).user }

    context 'when co-presenter who paid for himself and session start really soon' do
      let(:session) { create(:immersive_session) }

      before do
        session.co_presenters << current_user.presenter
        create(:real_stripe_transaction, type: TransactionTypes::IMMERSIVE, purchased_item: session, user: current_user)
        session.update({ start_at: 2.minutes.from_now })
        session.reload
      end

      it { expect(ability).to be_able_to :live_opt_out_and_get_money_refund, session }
    end
  end

  describe '#live_opt_out(session)' do
    let(:current_user) { create(:participant).user }

    context 'when session has not started yet' do
      let(:session) { create(:immersive_session, start_at: 4.hours.from_now.beginning_of_hour) }

      context 'when real participant' do
        before do
          session.immersive_participants << current_user.participant
          session.reload
        end

        it { expect(ability).to be_able_to :live_opt_out, session }
      end

      context 'when real co-presenter' do
        before do
          create(:presenter, user: current_user)
          session.co_presenters << current_user.presenter
          session.reload
        end

        it { expect(ability).to be_able_to :live_opt_out, session }
      end

      context 'when random user' do
        it { expect(ability).not_to be_able_to :live_opt_out, session }
      end
    end

    context 'when session has started' do
      let(:session) { create(:immersive_session) }

      context 'when real participant' do
        before do
          session.immersive_participants << current_user.participant

          def session.started?
            true
          end
        end

        it { expect(ability).not_to be_able_to :live_opt_out, session }
      end
    end
  end

  describe '#edit(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :edit, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :edit, session }
    end
  end

  describe '#cancel(session)' do
    context 'when session has not started yet' do
      context 'when owner' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization, user: current_user) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

        it { expect(ability).to be_able_to :cancel, session }
      end

      context 'when member' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

        before do
          member = create(:organization_membership, organization: organization, user: current_user)
          create(:access_management_groups_credential,
                 credential: create(:access_management_credential, code: :cancel_session), group: role)
          create(:access_management_groups_member, organization_membership: member, group: role)
        end

        it { expect(ability).to be_able_to :cancel, session }
      end

      context 'when not member' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel) }

        it { expect(ability).not_to be_able_to :cancel, session }
      end
    end

    context 'when session has started already' do
      context 'when owner' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization, user: current_user) }
        let(:channel) { create(:listed_channel, organization: organization) }
        let(:session) do
          session = create(:immersive_session, channel: channel, presenter: current_user.presenter)

          def session.started?
            true
          end
        end

        it { expect(ability).not_to be_able_to :cancel, session }
      end
    end
  end

  describe '#clone(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :clone, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :clone_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :clone, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :clone, session }
    end
  end

  describe '#invite_to_session(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :invite_to_session, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :invite_to_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :invite_to_session, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :invite_to_session, session }
    end
  end

  describe '#start(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :start, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :start_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :start, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :start, session }
    end
  end

  describe '#end(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :end, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :end_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :end, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :end, session }
    end
  end

  describe '#add_products(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { expect(ability).to be_able_to :add_products, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :add_products_to_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :add_products, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { expect(ability).not_to be_able_to :add_products, session }
    end
  end

  describe '#create_or_update_review_comment(session)' do
    context 'when not finished' do
      let!(:session) do
        create(:immersive_session).tap do |s|
          s.immersive_participants << current_user.participant
        end
      end

      let(:current_user) { create(:participant).user }

      it { expect(ability).not_to be_able_to :create_or_update_review_comment, session }
    end

    context 'when finished and actual participant and already rated' do
      let(:session) do
        create(:immersive_session).tap do |s|
          create(:real_stripe_transaction, purchased_item: s, user: current_user)

          s.immersive_participants << current_user.participant
          s.start_at = 1.day.ago
          s.save(validate: false)
        end
      end
      let(:rate) { create(:rate, rater: current_user, rateable: session) }

      let(:current_user) { create(:participant).user }

      before do
        rate
      end

      it { expect(ability).to be_able_to :create_or_update_review_comment, session }
    end
  end

  describe '#be_added_to_waiting_list_as_non_free_trial_immersive_method(session)' do
    context 'when not paid already and session is valid' do
      let(:session) { create(:immersive_session) }

      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when session is private' do
      let(:session) { create(:immersive_session, private: true) }

      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when one-on-one session' do
      let(:session) { create(:one_on_one_session) }
      let(:current_user) { create(:user) }

      context 'when slot is not bought' do
        it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end

      context 'when slot is already bought' do
        before do
          session.immersive_participants << create(:participant)
        end

        it { expect(ability).to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end
    end

    context 'when session with livestream-only delivery method' do
      let(:session) { create(:session_with_livestream_only_delivery) }

      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when already paid' do
      let(:session) { create(:immersive_session) }

      let(:current_user) { create(:participant).user }

      before do
        session.immersive_participants << current_user.participant
        session.reload
      end

      it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when number of participants is already over the limit' do
      let!(:session) do
        create(:immersive_session, min_number_of_immersive_and_livestream_participants: 2,
                                   max_number_of_immersive_participants: 3)
      end

      let(:current_user) { create(:participant).user }

      context 'when you are not yet a participant of that session' do
        before do
          session.immersive_participants << create(:participant)
          session.immersive_participants << create(:participant)
          session.immersive_participants << create(:participant)
        end

        it { expect(ability).to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end

      context 'when you are already a participant of that session' do
        before do
          session.immersive_participants << create(:participant)
          session.immersive_participants << create(:participant)
          session.immersive_participants << current_user.participant
        end

        it { expect(ability).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end
    end
  end

  describe '#publish(session)' do
    context 'when given unlisted channel' do
      let(:current_user) { session.presenter.user }

      context 'when given private session ' do
        let(:session) { create(:immersive_session, private: true) }

        before do
          session.update_column(:status, 'unpublished')
        end

        it { expect(session.channel).not_to be_listed }
        it { expect(session).not_to be_published }

        it { expect(ability).to be_able_to :publish, session }
      end
    end

    context 'when given published session' do
      let(:session) { create(:published_session) }
      let(:current_user) { session.organizer }

      it { expect(session).to be_published }

      it { expect(ability).not_to be_able_to :publish, session }
    end
  end

  describe '#have_in_wishlist' do
    let!(:session) { create(:immersive_session) }

    context 'when you are not signed in' do
      let(:current_user) { nil }

      it { expect(ability).to be_able_to :have_in_wishlist, session }
    end

    context 'when you are the creator of channel' do
      let(:current_user) { session.organizer }

      it { expect(ability).not_to be_able_to :have_in_wishlist, session }
    end

    context 'when you are not the creator of channel' do
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :have_in_wishlist, session }
    end
  end

  describe '#read(session)' do
    context 'when given organizer' do
      let(:current_user) { session.organizer }
      let(:session) { create(:immersive_session, private: true) }

      it { expect(ability).to be_able_to :read, session }
    end

    context 'when given adult session' do
      context 'when not signed in user' do
        let(:current_user) { nil }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(ability).not_to be_able_to :read, session }
      end

      context 'when given service_admin user' do
        let(:current_user) { create(:user_service_admin) }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(ability).to be_able_to :read, session }
      end

      context 'when signed in young user' do
        let(:current_user) { create(:user, birthdate: 12.years.ago) }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(ability).not_to be_able_to :read, session }
      end
    end

    context 'when given not signed in user and non-private session' do
      let(:current_user) { nil }
      let(:session) { create(:immersive_session, private: false) }

      it { expect(ability).to be_able_to :read, session }
    end

    context 'when given private session' do
      let(:session) { create(:immersive_session, private: true) }

      context 'when not involved user' do
        let(:current_user) { create(:user) }

        it { expect(ability).not_to be_able_to :read, session }
      end

      context 'when given service_admin user' do
        let(:current_user) { create(:user_service_admin) }

        it { expect(ability).to be_able_to :read, session }
      end

      context 'when not signed in user' do
        let(:current_user) { nil }

        it { expect(ability).not_to be_able_to :read, session }
      end

      context 'when invited participant' do
        let(:current_user) { create(:participant).user }

        before do
          session.session_invited_immersive_participantships.create(participant: current_user.participant)
        end

        it { expect(ability).to be_able_to :read, session }
      end
    end
  end
end
