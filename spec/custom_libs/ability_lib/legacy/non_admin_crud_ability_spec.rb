# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Legacy::NonAdminCrudAbility do
  let(:non_admin) { described_class.new(current_user) }

  describe '#create_1st_channel' do
    context 'when given invited co-presenter' do
      let(:session) do
        create(:immersive_session).tap do |s|
          s.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        end
      end
      let(:current_user) { create(:presenter).user }

      it { expect(non_admin).to be_able_to :create_1st_channel, current_user }
    end
  end

  describe '#be_notified_about_1st_published_session(channel)' do
    context 'when given channel first upcoming session' do
      let(:current_user) { User.new }
      let(:channel) { create(:published_session).channel.reload }

      it { expect(non_admin).not_to be_able_to :be_notified_about_1st_published_session, channel }
    end

    context 'when given new listed channel without any scheduled sessions' do
      let(:current_user) { User.new }
      let(:channel) { create(:listed_channel) }

      it { expect(non_admin).to be_able_to :be_notified_about_1st_published_session, channel }
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

      it { expect(non_admin).not_to be_able_to :create_or_update_review_comment, session }
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

      it { expect(non_admin).to be_able_to :create_or_update_review_comment, session }
    end
  end

  describe '#be_added_to_waiting_list_as_non_free_trial_immersive_method(session)' do
    context 'when not paid already and session is valid' do
      let(:session) { create(:immersive_session) }

      let(:current_user) { create(:user) }

      it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when session is private' do
      let(:session) { create(:immersive_session, private: true) }

      let(:current_user) { create(:user) }

      it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when one-on-one session' do
      let(:session) { create(:one_on_one_session) }
      let(:current_user) { create(:user) }

      context 'when slot is not bought' do
        it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end

      context 'when slot is already bought' do
        before do
          session.immersive_participants << create(:participant)
        end

        it { expect(non_admin).to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end
    end

    context 'when session with livestream-only delivery method' do
      let(:session) { create(:session_with_livestream_only_delivery) }

      let(:current_user) { create(:user) }

      it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
    end

    context 'when already paid' do
      let(:session) { create(:immersive_session) }

      let(:current_user) { create(:participant).user }

      before do
        session.immersive_participants << current_user.participant
        session.reload
      end

      it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
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

        it { expect(non_admin).to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
      end

      context 'when you are already a participant of that session' do
        before do
          session.immersive_participants << create(:participant)
          session.immersive_participants << create(:participant)
          session.immersive_participants << current_user.participant
        end

        it { expect(non_admin).not_to be_able_to :be_added_to_waiting_list_as_non_free_trial_immersive_method, session }
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

        it { expect(non_admin).to be_able_to :publish, session }
      end
    end

    context 'when given published session' do
      let(:session) { create(:published_session) }
      let(:current_user) { session.organizer }

      it { expect(session).to be_published }

      it { expect(non_admin).not_to be_able_to :publish, session }
    end
  end

  describe '#have_in_wishlist' do
    let!(:session) { create(:immersive_session) }

    context 'when you are not signed in' do
      let(:current_user) { nil }

      it { expect(non_admin).to be_able_to :have_in_wishlist, session }
    end

    context 'when you are the creator of channel' do
      let(:current_user) { session.organizer }

      it { expect(non_admin).not_to be_able_to :have_in_wishlist, session }
    end

    context 'when you are not the creator of channel' do
      let(:current_user) { create(:user) }

      it { expect(non_admin).to be_able_to :have_in_wishlist, session }
    end
  end

  describe '#read(user)' do
    context 'when given user himself' do
      let(:current_user) { create(:user) }

      it { expect(non_admin).to be_able_to :read, current_user }
    end

    context 'when given non-presenter user' do
      let(:current_user) { create(:user) }

      it { expect(non_admin).to be_able_to :read, create(:user) }
    end

    context 'when given signed in user' do
      let(:current_user) { create(:user) }
      let(:user) { create(:presenter).user }

      it { expect(non_admin).to be_able_to :read, user }
    end

    context 'when given unsigned in user' do
      let(:current_user) { nil }
      let(:user) { create(:presenter).user }

      it { expect(non_admin).to be_able_to :read, user }
    end

    context 'when given service_admin in user' do
      let(:current_user) { create(:user_service_admin) }
      let(:user) { create(:user) }

      it { expect(non_admin).to be_able_to :read, user }
    end
  end

  describe '#read(session)' do
    context 'when given organizer' do
      let(:current_user) { session.organizer }
      let(:session) { create(:immersive_session, private: true) }

      it { expect(non_admin).to be_able_to :read, session }
    end

    context 'when given adult session' do
      context 'when not signed in user' do
        let(:current_user) { nil }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(non_admin).not_to be_able_to :read, session }
      end

      context 'when given service_admin user' do
        let(:current_user) { create(:user_service_admin) }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(non_admin).to be_able_to :read, session }
      end

      context 'when signed in young user' do
        let(:current_user) { create(:user, birthdate: 12.years.ago) }
        let(:session) { create(:immersive_session, private: false, age_restrictions: 1) }

        it { expect(non_admin).not_to be_able_to :read, session }
      end
    end

    context 'when given not signed in user and non-private session' do
      let(:current_user) { nil }
      let(:session) { create(:immersive_session, private: false) }

      it { expect(non_admin).to be_able_to :read, session }
    end

    context 'when given private session' do
      let(:session) { create(:immersive_session, private: true) }

      context 'when not involved user' do
        let(:current_user) { create(:user) }

        it { expect(non_admin).not_to be_able_to :read, session }
      end

      context 'when given service_admin user' do
        let(:current_user) { create(:user_service_admin) }

        it { expect(non_admin).to be_able_to :read, session }
      end

      context 'when not signed in user' do
        let(:current_user) { nil }

        it { expect(non_admin).not_to be_able_to :read, session }
      end

      context 'when invited participant' do
        let(:current_user) { create(:participant).user }

        before do
          session.session_invited_immersive_participantships.create(participant: current_user.participant)
        end

        it { expect(non_admin).to be_able_to :read, session }
      end
    end
  end
end
