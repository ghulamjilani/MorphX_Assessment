# frozen_string_literal: true
require 'spec_helper'
require 'sidekiq/testing'

describe Session do
  let(:session) { create(:immersive_session) }

  describe 'validations' do
    subject { build(:immersive_session) }

    describe 'checks recurring_settings_limit' do
      let(:session) do
        build(:immersive_session, free_trial_for_first_time_participants: true, immersive_access_cost: 12.99,
                                  max_number_of_immersive_participants: 2,
                                  recurring_settings: ActiveSupport::HashWithIndifferentAccess.new({
                                                                                                     active: 'on',
                                                                                                     until: 'occurrence',
                                                                                                     occurrence: '20',
                                                                                                     days: %w[sunday monday tuesday wednesday thursday friday saturday]
                                                                                                   }))
      end

      context 'subscriptions disabled' do
        before do
          Rails.application.credentials.global[:service_subscriptions][:enabled] = false
          session.valid?
        end

        it { expect(session.errors[:recurring_settings]).to be_empty }
      end

      context 'subscriptions enabled' do
        before do
          Rails.application.credentials.global[:service_subscriptions][:enabled] = true
        end

        after do
          Rails.application.credentials.global[:service_subscriptions][:enabled] = false
        end

        context 'organization.split_revenue_plan true' do
          before do
            session.channel.organization.update(split_revenue_plan: true)
            session.valid?
          end

          it { expect(session.errors[:recurring_settings]).to be_empty }
        end

        context 'organization.split_revenue_plan false' do
          before do
            session.channel.organization.update(split_revenue_plan: false)
            session.valid?
          end

          it { expect(session.errors[:recurring_settings]).not_to be_empty }

          context 'when subscription exists' do
            before do
              create(:stripe_service_subscription, user: session.channel.organization.user, organization: session.channel.organization, current_period_end: 3.days.from_now)
              session.valid?
            end

            it { expect(session.errors[:recurring_settings]).not_to be_empty }
            it { expect { session.save }.to change(described_class, :count).by(0) }
          end
        end
      end
    end

    describe 'checks free slots compliance' do
      let(:session) do
        build(:immersive_session, free_trial_for_first_time_participants: true, immersive_access_cost: 12.99,
                                  max_number_of_immersive_participants: 2)
      end

      it 'less/equal' do
        session.immersive_free_slots = 3
        session.valid?
        expect(session.errors[:immersive_free_slots]).to eq(['must be less than or equal to 2'])
      end

      it 'greater/equal' do
        session.immersive_free_slots = -1
        session.valid?
        expect(session.errors[:immersive_free_slots]).to eq(['must be greater than or equal to 0'])
      end
    end

    it 'does not allow completely free session to have non-zero costs' do
      session = create(:immersive_session)
      session.immersive_free = true
      session.save!

      expect(session.reload.immersive_access_cost).to be_zero
    end

    it 'destroys pay promises when completely free session granted' do
      create(:organizer_session_pay_promise_for_attended_user) # irrelevant session
      session = create(:pending_completely_free_session)
      create(:organizer_session_pay_promise_for_attended_user, abstract_session: session,
                                                               co_presenter: create(:presenter))
      expect do
        session.update!(status: ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED)
      end.to change(
        OrganizerAbstractSessionPayPromise, :count
      ).from(2).to(1)
    end

    it 'nullifies costs when completely free session granted' do
      session = create(:pending_completely_free_session)
      expect { session.update!(status: ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED) }.to change {
                                                                                                    session.reload.status
                                                                                                  }.from(::Session::Statuses::REQUESTED_FREE_SESSION_PENDING).to(::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED)
    end

    describe 'checks business subscription' do
      let(:session) do
        build(:immersive_session, channel: create(:approved_channel, organization: create(:organization)))
      end

      before do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = true
        session.valid?
      end

      after do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = false
      end

      it {
        expect(session.errors[:business_plan]).to eq(["You can't create session because of your current Business plan limits"])
      }
    end

    describe 'validates if service type can be changed' do
      let(:session) { create(:immersive_session) }
      let(:new_wa) { create(:ffmpegservice_account_ipcam, organization: session.channel.organization) }

      before do
        session
      end

      it 'allows to switch service_type before start' do
        Timecop.travel(session.start_at - 1.minute) do
          session.update(service_type: 'rtmp')
          expect(session.valid?).to be_truthy
        end
      end

      it 'allows to switch ffmpegservice account before start' do
        Timecop.travel(session.start_at - 1.minute) do
          session.update(ffmpegservice_account_id: new_wa.id)
          expect(session.valid?).to be_truthy
        end
      end

      it 'does not allow to switch service_type after start' do
        Timecop.travel(session.start_at + 1.minute) do
          session.update(service_type: 'rtmp')
          expect(session.errors.attribute_names).to include(:service_type)
        end
      end

      it 'does not allow to switch wa after start' do
        Timecop.travel(session.start_at + 1.minute) do
          session.update(ffmpegservice_account_id: new_wa.id)
          expect(session.errors.attribute_names).to include(:service_type)
        end
      end
    end
  end

  describe 'callbacks' do
    subject(:session) { create(:recorded_session) }

    let(:channel) { subject.channel }

    before do
      stub_request(:any, /.*chat.webrtcservice.com.*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'updates session slug after channel slug changed' do
      Sidekiq::Testing.inline! do
        expect do
          channel.slug = 'trololo'
          channel.save
          session.reload
        end.to change(session, :slug)
      end
    end
  end

  describe 'scopes' do
    describe '.interactive_access_tokens' do
      let(:session) { create(:interactive_access_token).session }

      it { expect(session.interactive_access_tokens.count.positive?).to be_truthy }
    end

    describe '.individual_interactive_tokens' do
      let(:session) { create(:interactive_access_token_individual).session }

      it { expect(session.individual_interactive_tokens.count.positive?).to be_truthy }
    end

    describe '.shared_interactive_token' do
      let(:session) { create(:interactive_access_token_shared).session }

      it { expect(session.shared_interactive_token).to be_truthy }
    end
  end

  describe '#total_donations_amount' do
    it {
      expect { create(:paypal_donation, abstract_session: session) }.to change {
                                                                          session.reload.total_donations_amount
                                                                        }.from(0).to(20.99)
    }
  end

  describe '#destroy' do
    let(:session) { create(:immersive_session) }

    before do
      session.session_invited_immersive_participantships.create(participant: create(:participant))
      session.session_participations.create!(participant: create(:participant), free_trial: false)
      session.livestreamers.create!(participant: create(:participant), free_trial: false)
    end

    it { expect { session.destroy }.to change(Livestreamer, :count).from(1).to(0) }
  end

  describe '#can_rate?(user)' do
    let!(:session) { create(:immersive_session) }
    let!(:user) { create(:participant).user }

    before do
      def session.finished?
        true
      end
    end

    # it { expect { session.immersive_participants << user.participant }.to change { session.can_rate?(user) }.from(false).to(true) }
    # it { expect { session.livestreamers.create!(participant: user.participant, free_trial: false) }.to change { session.can_rate?(user) }.from(false).to(true) }

    it { expect(session.can_rate?(user, ::Session::RateKeys::QUALITY_OF_CONTENT)).to be_falsey }

    context 'when immersive participant present' do
      before do
        session.immersive_participants << user.participant
      end

      it { expect(session.can_rate?(user, ::Session::RateKeys::QUALITY_OF_CONTENT)).to be_truthy }
    end

    context 'when livestreamer participant present' do
      before do
        session.livestreamers.create!(participant: user.participant, free_trial: false)
      end

      it { expect(session.can_rate?(user, ::Session::RateKeys::QUALITY_OF_CONTENT)).to be_truthy }
    end
  end

  describe '#paid_immersive_session_participations' do
    let(:session) { create(:immersive_session) }
    let(:participant) { create(:participant) }

    it 'works' do
      session.immersive_participants << participant
      expect do
        create(:real_stripe_transaction, type: TransactionTypes::IMMERSIVE, purchased_item: session,
                                         user: participant.user)
      end.to change(session, :paid_immersive_session_participations).from([]).to([SessionParticipation.last])
    end
  end

  describe '#paid_livestreamers' do
    let(:session) { create(:immersive_session) }
    let(:participant) { create(:participant) }

    it 'works' do
      session.livestream_participants << participant
      expect do
        create(:real_stripe_transaction, type: TransactionTypes::LIVESTREAM, purchased_item: session,
                                         user: participant.user)
      end.to change(session, :paid_livestreamers).from([]).to([Livestreamer.last])
    end
  end

  describe '#immersive_delivery_method?' do
    it { expect(create(:immersive_session)).to be_immersive_delivery_method }
    it { expect(create(:free_trial_immersive_session)).to be_immersive_delivery_method }
    it { expect(create(:completely_free_session)).to be_immersive_delivery_method }
  end

  describe '#display_level?' do
    subject { described_class.new(channel: channel).display_level? }

    context 'when given channel of performance type' do
      let(:channel) { create(:channel, channel_type: create(:performance_channel_type)) }

      it { is_expected.to be false }
    end

    context 'when given channel of non-performance type' do
      let(:channel) { create(:channel, channel_type: create(:instructional_channel_type)) }

      it { is_expected.to be true }
    end
  end

  context 'when start_at changed' do
    # before { Timecop.freeze(Time.now) } # to avoid 1sec difference test fails
    let(:participant) { create(:participant) }
    let(:co_presenter1) { create(:presenter) }
    let(:co_presenter2) { create(:presenter) }

    let(:session) do
      create(:immersive_session).tap do |session|
        session.immersive_participants << participant
        create(:real_stripe_transaction, purchased_item: session, user: participant.user)

        session.co_presenters << co_presenter1
        create(:real_stripe_transaction, purchased_item: session, user: co_presenter1.user)

        create(:organizer_session_pay_promise, abstract_session: session, co_presenter: co_presenter2)
        session.co_presenters << co_presenter2
      end
    end

    before do
      @initial_scheduled_times = []
    end

    it { expect(PendingRefund.count).to be_zero }

    it 're-schedules SessionStartReminder jobs' do
      # Sidekiq::Testing.inline! do
      # session.start_at = 1.hour.since(session.start_at)
      # session.former_start_at = session.start_at
      # session.save!
      #
      # expect(SessionStartReminder).to have_scheduled(session.id, participant.user.id, EmailOnlyFormatPolicy.to_s)
      #
      # updated_scheduled_times = ResqueSpec.queues['high_scheduled'].select { |hash| hash[:class] == 'SessionStartReminder' }.collect { |hash| hash[:time] }
      #
      # # I would rather keep this "logging" as it is, otherwise it may fail and we never notice
      # expect(@initial_scheduled_times).not_to eq(updated_scheduled_times)
      # end
    end

    describe 'offers pending refunds for paid participants and co-presenters if they dont like updated start_at' do
      before do
        session.start_at = 1.hour.since(session.start_at)
        session.former_start_at = session.start_at
        session.save!
      end

      it { expect(PendingRefund.count).to eq(2) }
      it { expect(PendingRefund.all.collect(&:user_id).sort).to eq([participant.user_id, co_presenter1.user_id].sort) }
    end

    # find all changes by TEMPORARYDISABLE
    it 'notifies co-presenters with session pay promise from organizer' do
      mailer = double
      allow(mailer).to receive(:deliver_later)
      allow(SessionMailer).to receive(:free_abstract_session_notify_about_changed_start_at).once.with(session.id,
                                                                                                      co_presenter2).and_return(mailer)
      session.start_at = 1.hour.since(session.start_at)
      session.save!
    end

    describe 'handles use case when Start At is changed several times before refund is reimbursed' do
      before do
        session.start_at = 1.hour.since(session.start_at)
        session.former_start_at = session.start_at
        session.save!
      end

      it { expect(PendingRefund.count).to eq(2) }
      it { expect(PendingRefund.all.collect(&:user_id).sort).to eq([participant.user_id, co_presenter1.user_id].sort) }

      it 'change second time' do
        session = described_class.last
        session.start_at = 9.hours.from_now.beginning_of_hour
        session.save!
        expect(PendingRefund.all.collect(&:user_id).sort).to eq([participant.user_id, co_presenter1.user_id].sort)
      end
    end
  end

  describe '#finished?' do
    describe 'works' do
      let(:start_at) { Time.zone.now.beginning_of_hour + 1.month }
      let!(:session) do
        create(:immersive_session, status: 'published', start_at: Chronic.parse(start_at.strftime('%b %d, %Y at %H:%M')),
                                   duration: 60)
      end

      it {
        Timecop.freeze Chronic.parse((start_at - 15.minutes).strftime('%b %d, %Y at %H:%M')) {
                         expect(session).not_to be_finished
                       }
      }

      it {
        Timecop.freeze Chronic.parse((start_at + 15.minutes).strftime('%b %d, %Y at %H:%M')) {
                         expect(session).not_to be_finished
                       }
      }

      it {
        Timecop.freeze Chronic.parse((start_at + 61.minutes).strftime('%b %d, %Y at %H:%M')) {
                         expect(session).to be_finished
                       }
      }

      it { expect(session).not_to be_finished }

      it 'for stopped session' do
        session.stopped_at = 2.seconds.ago
        expect(session).to be_finished
      end
    end
  end

  describe '.ongoing_or_upcoming' do
    let(:passed_session) { create(:immersive_session).tap { |s| s.start_at = 1.day.ago; s.save(validate: false) } }
    let(:started_but_still_active_session) do
      create(:immersive_session).tap do |s|
        s.start_at = 1.minute.ago; s.save(validate: false)
      end
    end
    let(:upcoming_session) { create(:immersive_session).tap { |s| expect(s).to be_upcoming } }

    it 'works' do
      started_but_still_active_session
      upcoming_session
      expect(described_class.ongoing_or_upcoming.sort).to eq([started_but_still_active_session, upcoming_session].sort)
    end
  end

  describe '.upcoming' do
    let(:passed_session) { create(:immersive_session).tap { |s| s.start_at = 1.day.ago; s.save(validate: false) } }
    let(:started_but_still_active_session) do
      create(:immersive_session).tap do |s|
        s.start_at = 1.minute.ago; s.save(validate: false)
      end
    end
    let(:session2) { build(:immersive_session, start_at: 1.day.from_now.beginning_of_hour) }

    it 'works' do
      passed_session
      session2.save
      started_but_still_active_session
      expect(described_class.upcoming.sort).to eq([session2, started_but_still_active_session].sort)
    end
  end

  describe '.is_public' do
    let!(:session1) { create(:immersive_session, private: false) }
    let!(:session2) { create(:immersive_session, private: false) }

    it 'works' do
      create(:immersive_session, private: true)
      expect(described_class.is_public.sort).to eq([session1, session2].sort)
    end
  end

  describe '#can_change_start_at?' do
    subject { session.can_change_start_at? }

    context 'when existing session not yet started' do
      let(:session) { create(:immersive_session) }

      it { is_expected.to be true }
    end

    context 'when existing session already started' do
      let(:session) { described_class.new(start_at: 2.years.ago) }

      it { is_expected.to be true }
    end

    context 'when new unpersisted session' do
      let(:session) { build(:immersive_session) }

      it { is_expected.to be true }
    end
  end

  describe '.wished_by' do
    subject { described_class.wished_by(user) }

    let(:wishlist_item) { create(:wishlist_item) }
    let(:user) { wishlist_item.user }
    let(:session) { wishlist_item.model }

    before do
      create(:immersive_session)
      create(:wishlist_item)
    end

    it { is_expected.to eq([session]) }
  end

  describe '.valid_durations' do
    it 'works' do
      expect(described_class.new.valid_durations).to eq((15..180).step(5).to_a)
    end
  end

  describe '#remind_at_times' do
    let(:user) { create(:user) }

    context 'when session is in far future' do
      let(:session) { create(:immersive_session, start_at: 100.hours.from_now.beginning_of_hour) }

      it 'are all ON by default' do
        expect(session.remind_about_start_at_times_via_email(user)).to eq([72.hours.until(session.start_at),
                                                                           24.hours.until(session.start_at), 6.hours.until(session.start_at), 1.hour.until(session.start_at), 15.minutes.until(session.start_at)])
      end

      it 'takes user/session reminder settings into account' do
        skip unless ENV['USER'] == 'nfedyashev' # FIXME: wtf?
        attrs = { hrs_72_via_email: '1', hrs_24_via_email: '0', hrs_6_via_email: '0', hrs_1_via_email: '0',
                  mins_15_via_email: '1', session: session }
        ModelConcerns::Settings::Notification.new(attrs).save_for(user)
        expect(session.remind_about_start_at_times_via_email(user)).to eq([72.hours.until(session.start_at),
                                                                           1.hour.until(session.start_at), 15.minutes.until(session.start_at)])
      end
    end

    context 'when session starts pretty soon' do
      let(:session) { create(:immersive_session, start_at: 10.hours.from_now.beginning_of_hour) }

      it 'are all ON by default but skips scheduled in past reminders' do
        expect(session.remind_about_start_at_times_via_email(user)).to eq([6.hours.until(session.start_at),
                                                                           1.hour.until(session.start_at), 15.minutes.until(session.start_at)])
      end
    end
  end

  describe '#invited_users_as_json' do
    let(:session) { create(:immersive_session) }
    let(:participant1) { create(:participant) }
    let(:participant2) { create(:participant) }
    let(:presenter1) { create(:presenter) }

    it 'works' do
      session.session_invited_immersive_co_presenterships.create(presenter: presenter1, status: 'accepted')
      session.session_invited_immersive_participantships.create(participant: participant1, status: 'accepted')
      session.session_invited_livestream_participantships.create(participant: participant1, status: 'pending')
      session.session_invited_immersive_participantships.create(participant: participant2)
      expect { session.invited_users_as_json }.not_to raise_error
    end
  end

  describe 'time overlap' do
    subject(:session) { build :immersive_session, duration: 60, channel: channel }

    let(:start_time) { Time.zone.now.beginning_of_hour + 1.hour + 15.minutes }
    let(:channel) { create :approved_channel }

    before do
      ENV['SKIP_OVERLAP_CHECK'] = nil
    end

    it 'has time overlap error with another started session' do
      FactoryBot.create :immersive_session, start_at: start_time, duration: 60, channel: channel
      Timecop.travel(start_time + 10.minutes) do
        session.update(start_at: start_time + 30.minutes)
        expect(session.errors[:'room.base'][0]).to include('is scheduled for this time period. Please adjust the Start time or the duration')
      end
    end

    it 'has time overlap error with another planed session' do
      FactoryBot.create(:immersive_session, start_at: start_time + 30.minutes, duration: 60, channel: channel)
      session.update(start_at: start_time)
      expect(session.errors[:'room.base'][0]).to include('is scheduled for this time period. Please adjust the Start time or the duration')
    end

    it 'does not have time overlap if another session is cancelled' do
      FactoryBot.create :cancelled_session, start_at: start_time + 30.minutes, duration: 60, channel: channel
      session.start_at = start_time
      session.save
      expect(session).not_to be_new_record
    end

    it 'does not has time overlap error when it does not overlap' do
      FactoryBot.create :immersive_session, start_at: start_time + 30.minutes, duration: 60, channel: channel
      session.start_at = start_time + 30.minutes + 60.minutes
      session.save
      expect(session).not_to be_new_record
    end

    it 'does not has time overlap error during update' do
      session.start_at = start_time + 30.minutes
      session.save
      session.update(start_at: start_time - 15.minutes)
      expect(session.errors).to be_empty
    end
  end

  describe '.visible_for' do
    describe 'approved channel private session' do
      let(:session) { create(:immersive_session, private: true) }
      let(:presenter) { create(:presenter) }
      let(:participant) { create(:participant) }

      it 'not visible for livestream_participants/immersive_participants' do
        expect(described_class.visible_for(participant.user)).not_to include(session)
      end

      it 'not visible for co-presenters' do
        expect(described_class.visible_for(presenter.user)).not_to include(session)
      end

      it 'visible for immersive_participants' do
        session.immersive_participants << participant
        expect(described_class.visible_for(participant.user)).to include(session)
      end

      it 'visible for livestream_participants' do
        session.livestream_participants << participant
        expect(described_class.visible_for(participant.user)).to include(session)
      end

      it 'visible for co-presenters' do
        session.co_presenters << presenter
        expect(described_class.visible_for(presenter.user)).to include(session)
      end
    end

    describe 'not approved channel private session' do
      let(:session) do
        channel = create(:rejected_channel)
        create(:immersive_session, channel: channel, private: true)
      end

      it 'is not visible for participant' do
        participant = create(:participant)
        session.immersive_participants << participant
        expect(described_class.visible_for(participant.user)).not_to include(session)
      end

      it 'is not visible for co-presenters' do
        presenter = create(:presenter)
        session.co_presenters << presenter
        expect(described_class.visible_for(presenter.user)).not_to include(session)
      end
    end

    it 'is not visible is no user in params' do
      session = create(:immersive_session, private: true)
      expect(described_class.visible_for(nil)).not_to include(session)
    end
  end

  describe '#interactive_slots_available?' do
    subject(:slots_available) { session.interactive_slots_available? }

    context 'when given immersive session' do
      context 'when given one-on-one type session' do
        context 'when slots available' do
          let(:session) { create(:one_on_one_session) }

          it { expect(slots_available).to be_truthy }
        end

        context 'when no slots available' do
          let(:session) { create(:session_participation, session: create(:one_on_one_session)).session }

          it { expect(slots_available).to be_falsey }
        end
      end

      context 'when given group type session' do
        context 'when slots available' do
          let(:session) do
            create(:session_participation,
                   session: create(:immersive_session, max_number_of_immersive_participants: 3)).session
          end

          it { expect(slots_available).to be_truthy }
        end
      end

      context 'when no slots available' do
        let(:group_session) do
          create(:session_participation,
                 session: create(:immersive_session, max_number_of_immersive_participants: 2)).session
        end
        let(:session) { create(:room_member_participant, room: group_session.room).room.session }

        it { expect(slots_available).to be_falsey }
      end
    end

    context 'for livestream only session' do
      let(:session) { create(:session_with_livestream_only_delivery) }

      it { expect(slots_available).to be_falsey }
    end
  end

  describe '#unique_view_group_start_at' do
    let(:session) { build(:session) }

    it { expect { session.unique_view_group_start_at }.not_to raise_error }
  end
end
