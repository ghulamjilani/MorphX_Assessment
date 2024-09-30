# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Legacy::AccountingAbility do
  let(:acc_ab) { described_class.new(current_user) }

  describe '#accept_or_reject_invitation(session)' do
    describe 'participant role' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:published_session) }

      context 'when invited and pending action' do
        before { session.session_invited_immersive_participantships.create(participant: current_user.participant) }

        it { expect(acc_ab).to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already rejected' do
        before do
          create(:rejected_session_invited_immersive_participantship, session: session,
                                                                      participant: current_user.participant)
        end

        it { expect(acc_ab).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already accepted' do
        before do
          create(:accepted_session_invited_immersive_participantship, session: session,
                                                                      participant: current_user.participant)
        end

        it { expect(acc_ab).not_to be_able_to :accept_or_reject_invitation, session }
      end
    end

    describe 'co-presenter role' do
      let(:current_user) { create(:presenter).user }
      let(:session) { create(:immersive_session) }

      context 'when invited and pending action' do
        before { session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter) }

        it { expect(acc_ab).to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already rejected' do
        before do
          create(:rejected_session_invited_immersive_co_presentership, session: session,
                                                                       presenter: current_user.presenter)
        end

        it { expect(acc_ab).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when invited and already accepted' do
        before do
          create(:accepted_session_invited_immersive_co_presentership, session: session,
                                                                       presenter: current_user.presenter)
        end

        it { expect(acc_ab).not_to be_able_to :accept_or_reject_invitation, session }
      end

      context 'when given a session with livestream-only delivery method' do
        let(:session) { create(:session_with_livestream_only_delivery) }

        before { session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter) }

        it { expect(acc_ab).to be_able_to :accept_or_reject_invitation, session }
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

      it { expect(acc_ab).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(acc_ab).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given new free trial session and not logged in user' do
      let(:current_user) { nil }
      let(:session) do
        create(:session_with_livestream_only_delivery, free_trial_for_first_time_participants: true,
                                                       livestream_free_slots: 2)
      end

      it { expect(acc_ab).to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given free trial session but current_user has already been trial user of another session in this channel' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      before do
        session2 = create(:free_trial_livestream_session, channel: session.channel, presenter: session.presenter)
        create(:livestreamer, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(acc_ab).not_to be_able_to :obtain_free_trial_livestream_access, session }
    end

    context 'when given user that already used immersive free trial in similar session' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      before do
        session2 = create(:free_trial_immersive_session, channel: session.channel, presenter: session.presenter)
        create(:session_participation, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(acc_ab).not_to be_able_to :obtain_free_trial_livestream_access, session }
    end
  end

  describe '#obtain_free_trial_immersive_access(session)' do
    context 'when given new free trial session and a new participant' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(acc_ab).to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given new free trial session and not logged in user' do
      let(:current_user) { nil }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(acc_ab).to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given new free trial session and invited co-presenter' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      before do
        create(:presenter, user: current_user)

        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
      end

      it { expect(acc_ab).not_to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given free trial session but current_user has already been trial user of another session in this channel' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_immersive_session) }

      before do
        session2 = create(:free_trial_immersive_session, channel: session.channel, presenter: session.presenter)
        create(:session_participation, session: session2, participant: current_user.participant, free_trial: true)
      end

      it { expect(acc_ab).not_to be_able_to :obtain_free_trial_immersive_access, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:free_trial_immersive_session) }

      it { expect(acc_ab).to be_able_to :obtain_free_trial_immersive_access, session }
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

      it { expect(acc_ab).to be_able_to :obtain_livestream_access_to_free_session, session }

      context 'when given service_admin' do
        let(:current_user) { create(:user_service_admin) }
        let(:session) { create(:completely_free_session) }

        it { expect(acc_ab).to be_able_to :obtain_livestream_access_to_free_session, session }
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

      it { expect(acc_ab).to be_able_to :obtain_livestream_access_to_free_session, session }
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

      it { expect(acc_ab).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given service_admin' do
      let(:current_user) { create(:user_service_admin) }
      let(:session) { create(:immersive_session) }

      it { expect(acc_ab).to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given completely free session and not logged in user' do
      let(:current_user) { nil }
      let(:session) do
        create(:completely_free_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(acc_ab).to be_able_to :obtain_immersive_access_to_free_session, session }
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

      it { expect(acc_ab).to be_able_to :obtain_immersive_access_to_free_session, session }
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

      it { expect(acc_ab).not_to be_able_to :obtain_immersive_access_to_free_session, session }
    end

    context 'when given free trial session' do
      let(:current_user) { create(:participant).user }
      let(:session) do
        create(:free_trial_immersive_session).tap do |s|
          s.status = ::Session::Statuses::PUBLISHED
          s.save!
        end
      end

      it { expect(acc_ab).not_to be_able_to :obtain_immersive_access_to_free_session, session }
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

      it { expect(acc_ab).not_to be_able_to :purchase_livestream_access, session }
    end

    context 'when not signed in' do
      let(:current_user) { nil }

      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(acc_ab).to be_able_to :purchase_livestream_access, session }
    end

    context 'when also a free_trial session' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:free_trial_livestream_session) }

      it { expect(acc_ab).to be_able_to :purchase_livestream_access, session }
    end

    context 'when still can be bought' do
      let(:current_user) { create(:participant).user }

      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(acc_ab).to be_able_to :purchase_livestream_access, session }
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

      it { expect(acc_ab).not_to be_able_to :purchase_immersive_access, session }
    end

    context 'when invited as co-presenter' do
      let(:session) do
        create(:one_on_one_session).tap do |session|
          session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        end
      end

      let(:current_user) { create(:presenter).user }

      it { expect(acc_ab).to be_able_to :purchase_immersive_access, session }
    end

    context 'when not signed in but there are available slots' do
      let(:current_user) { nil }

      let(:session) do
        create(:published_session, min_number_of_immersive_and_livestream_participants: 1,
                                   max_number_of_immersive_participants: 2, private: false)
      end

      it { expect(acc_ab).to be_able_to :purchase_immersive_access, session }
    end

    context 'when group session' do
      context 'when given free trial session' do
        let(:current_user) { create(:participant).user }
        let(:session) { create(:free_trial_immersive_session) }

        it { expect(acc_ab).to be_able_to :purchase_immersive_access, session }
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

        it { expect(acc_ab).not_to be_able_to :purchase_immersive_access, session1 }
        it { expect(acc_ab).to be_able_to :purchase_immersive_access, session2 }
      end

      context 'when  private' do
        let(:current_user) { create(:participant).user }
        let(:session) { create(:private_published_session) }

        it { expect(acc_ab).not_to be_able_to :purchase_immersive_access, session }

        it do
          session.session_invited_immersive_participantships.create(participant: current_user.participant)
          expect(acc_ab).to be_able_to :purchase_immersive_access, session
        end
      end
    end

    context 'when one-on-one public session' do
      let(:session) { create(:one_on_one_session, private: false) }

      context 'when not invited' do
        before { session.update!({ status: 'published' }) }

        let(:current_user) { create(:user) }

        it('when no one has purchased the slot yet') {
          expect(acc_ab).to be_able_to :purchase_immersive_access, session
        }

        it 'when someone else has bought the slot already' do
          session.immersive_participants << create(:participant)
          expect(acc_ab).not_to be_able_to :purchase_immersive_access, session
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

      it { expect(acc_ab).to be_able_to :live_opt_out_and_get_money_refund, session }
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

        it { expect(acc_ab).to be_able_to :live_opt_out, session }
      end

      context 'when real co-presenter' do
        before do
          create(:presenter, user: current_user)
          session.co_presenters << current_user.presenter
          session.reload
        end

        it { expect(acc_ab).to be_able_to :live_opt_out, session }
      end

      context 'when random user' do
        it { expect(acc_ab).not_to be_able_to :live_opt_out, session }
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

        it { expect(acc_ab).not_to be_able_to :live_opt_out, session }
      end
    end
  end

  describe '#change_status_as_participant(SessionInvitedImmersiveParticipantship)' do
    context 'when participantship has status pending' do
      let(:participantship) { create(:session_invited_immersive_participantship) }

      context 'when user is the invited participant' do
        let(:current_user) { participantship.participant.user }

        it { expect(acc_ab).to be_able_to :change_status_as_participant, participantship }
      end

      context 'when user is not the invited participant' do
        let(:current_user) { create(:user) }

        it { expect(acc_ab).not_to be_able_to :change_status_as_participant, participantship }
      end
    end

    context 'when participantship has status accepted/rejected' do
      let(:participantship) do
        create(%i[accepted_session_invited_immersive_participantship
                  rejected_session_invited_immersive_participantship].sample)
      end
      let(:current_user) { participantship.participant.user }

      it { expect(acc_ab).not_to be_able_to :change_status_as_participant, participantship }
    end
  end
end
