# frozen_string_literal: true

require 'spec_helper'

describe SessionsController do
  before do
    # Stub for dropbox_authorize_url
    dropbox_session = double('DropboxSession')
    allow(DropboxSession).to receive(:new).and_return(dropbox_session)
    allow(dropbox_session).to receive(:serialize).and_return('token')
    allow(dropbox_session).to receive(:get_authorize_url).and_return('#auth_url')
  end

  describe 'GET :index' do
    render_views

    before do
      sign_in(current_user, scope: :user)
    end

    let!(:session1) { create(:published_session, start_at: Time.zone.now.beginning_of_day + 1.day + 13.hours) }
    let!(:session2) do
      create(:published_session, start_at: Time.zone.now.beginning_of_day + 1.day + 18.hours + 30.minutes, duration: 30)
    end
    let!(:session3) { create(:published_session, start_at: Time.zone.now.beginning_of_day + 1.day + 19.hours) }
    let(:current_user) { session1.organizer }
    let(:format) { ['%m/%d/%Y', '%b %d, %Y'].sample } # has to respond to both formats
    let(:date_of_session) { session1.start_at.in_time_zone(Time.zone).strftime(format) }

    it 'has proper response format' do
      get :index, xhr: true, params: { date: date_of_session }, format: 'json'

      expect(response).to be_successful

      resp = JSON.parse response.body
      expect(resp['channels'].first['channel_name']).to eq('Channel #1')
      expect(resp['channels'].first['sessions'].length).to eq(2)
    end
  end

  describe 'POST :instant_remove_invited_user_from_video' do
    render_views
    let(:session) { create(:immersive_session) }
    let(:current_user) { session.organizer }

    it 'works' do
      sign_in current_user, scope: :user
      participant1 = create(:participant)
      session.session_invited_immersive_participantships.create!(participant: participant1)
      expect(SessionInvitedImmersiveParticipantship.count).to eq(1)

      post :instant_remove_invited_user_from_video, params: { id: session.id, email: participant1.email }, format: :js

      expect(response).to be_successful

      expect(SessionInvitedImmersiveParticipantship.count).to eq(0)
    end
  end

  describe 'GET :new' do
    before { sign_in current_user, scope: :user }

    context 'when given presenter with completed profile' do
      let!(:current_user) { channel.organizer }

      context 'when approved channel assigns free delivery method defaults' do
        let(:channel) { create(:approved_channel) }

        before do
          # create(:custom_description_field_label)
          get :new, params: { channel_id: channel.slug }
        end

        it { expect(assigns(:session).livestream_free).to eq(true) }
        it { expect(assigns(:session).immersive_free).to eq(false) }
        it { expect(assigns(:session).recorded_free).to eq(true) }
      end

      context 'when pending channel(not approved)' do
        let(:channel) { create(:channel) }
        let!(:current_user) { channel.organizer }

        before { sign_in current_user, scope: :user }

        it 'is not allowed' do
          get :new, params: { channel_id: channel.slug }
          expect(response).to be_redirect
          expect(flash[:error]).to be_present
        end
      end
    end
  end

  describe 'GET :preview_clone_modal' do
    render_views
    before { sign_in current_user, scope: :user }

    let!(:current_user) { session.organizer }

    context 'when given session with some invites' do
      let(:session) do
        create(:published_session).tap do |session|
          session.session_invited_immersive_participantships.create!(participant: create(:participant))
        end
      end

      it 'does not fail' do
        get :preview_clone_modal, params: { id: session.id }, format: :js
        expect(response).to be_successful
        expect(assigns(:session)).to eq(session)
      end
    end
  end

  describe 'GET :clone' do
    before { sign_in current_user, scope: :user }

    let(:organization) { create(:organization_with_subscription) }
    let!(:current_user) { organization.user }
    let(:channel) { create(:approved_channel, organization: organization) }
    let(:original_session) do
      create(:immersive_session, channel: channel, presenter: channel.organization.user.presenter)
    end

    context 'without invites and dropbox assets' do
      it 'works' do
        get :clone, params: { channel_id: channel.id, id: original_session.id }
        expect(response).to render_template('new')
      end
    end

    context 'with invites and dropbox assets' do
      it 'works' do
        participant2 = create(:participant)
        original_session.session_invited_immersive_participantships.create!(participant: participant2)
        create(:dropbox_material, abstract_session: original_session)

        get :clone,
            params: { channel_id: channel.id, id: original_session.id,
                      session: { SessionsHelper::Clone::INVITES => '1', SessionsHelper::Clone::DROPBOX_ASSETS => '1' } }
        expect(response).to render_template('new')
        expect(assigns(:session).session_invited_immersive_co_presenterships).to be_blank
        expect(assigns(:session).session_invited_immersive_participantships).not_to be_blank
        expect(assigns(:session).dropbox_materials).not_to be_blank
      end
    end

    context 'when multiroom ebabled' do
      let(:organization) { create(:organization_with_subscription, multiroom_status: :enabled) }
      let(:ffmpegservice_accounts) do
        [
          create(:ffmpegservice_account, organization: organization),
          create(:ffmpegservice_account_ipcam, organization: organization),
          create(:ffmpegservice_account_rtmp, organization: organization)
        ]
      end
      let(:selected_ffmpegservice_account) { ffmpegservice_accounts.sample }
      let(:original_session) do
        create(:immersive_session, channel: channel, presenter: channel.organization.user.presenter,
                                   ffmpegservice_account: selected_ffmpegservice_account)
      end

      before do
        get :clone, params: { channel_id: channel.id, id: original_session.id }
      end

      it { expect(assigns(:session).ffmpegservice_account_id).to eq(selected_ffmpegservice_account.id) }

      it { expect(assigns(:session).description).to eq(original_session.description) }
    end
  end

  describe 'PUT :update' do
    before do
      Timecop.freeze(current_time)
      sign_in current_user, scope: :user
    end

    let(:channel) { create(:approved_channel) }
    let(:session) do
      create(:immersive_session, start_at: Chronic.parse('Jan 6th, 2014 at 7:00pm'),
                                 channel: channel)
    end
    let(:current_user) { session.organizer }

    let(:current_time) { Chronic.parse('Jan 6th, 2014 at 6:45pm') }

    context 'when given valid settings' do
      before do
        @year = 2014
        @month = 1
        @day = 16 # in 10 days from frozen time
        @hour = 18
        @minute = 30

        put :update, params: { channel_id: channel.slug, id: session.slug, session: {
          adult: 1,
          age_restrictions: 1,
          duration: '60',
          free_trial_for_first_time_participants: false,
          immersive: '1',
          immersive_access_cost: '12.22',
          immersive_type: Session::ImmersiveTypes::GROUP,
          level: 'All Levels',
          max_number_of_immersive_participants: '15',
          min_number_of_immersive_and_livestream_participants: '2',
          private: true,
          record: '1',
          recorded_access_cost: '13.99',
          'start_at(1i)' => @year,
          'start_at(2i)' => @month,
          'start_at(3i)' => @day,
          'start_at(4i)' => @hour,
          'start_at(5i)' => @minute,
          livestream: '1',
          livestream_access_cost: '23.22'
        }, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT }
      end

      it 'works' do
        raise assigns[:session].errors.full_messages.inspect if assigns[:session] && assigns[:session].errors.present?

        expect(response).to be_redirect
        expect(Session.last.age_restrictions).to eq(1)
        expect(Session.last.level).to eq('All Levels')
      end
    end
  end

  describe 'POST :invited_users_portal' do
    let(:channel) { create(:approved_channel) }
    let(:session) { create(:published_session, channel: channel) }
    let(:current_user) { session.organizer }

    before do
      sign_in current_user, scope: :user
      create(:ffmpegservice_account)
    end

    context 'when given valid data and unregistered email address' do
      context 'with invited co-presenter' do
        before do
          post :invited_users_portal, xhr: true, params: { id: session.id, invited_users_attributes: [{ email: 'this@guy.com', state: ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER }].to_json }, format: :js
        end

        it { expect(response).to be_successful }
        it { expect(SessionJobs::EditInvitedUsersJob).to have(1).jobs }
        # end.to change(SessionInvitedImmersiveCoPresentership, :count).from(0).to(1)
      end

      context 'with invited interactive' do
        before do
          post :invited_users_portal, xhr: true, params: { id: session.id, invited_users_attributes: [{ email: 'this2@guy.com', state: ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE }].to_json }, format: :js
        end

        it { expect(response).to be_successful }
        it { expect(SessionJobs::EditInvitedUsersJob).to have(1).jobs }
      end
    end
  end

  describe 'POST :accept_invitation' do
    let!(:session) { create(:published_session) }

    context 'when given co presenter and organizer promised to pay for him' do
      let(:current_user) { create(:presenter).user }

      before do
        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        create(:organizer_session_pay_promise, abstract_session: session, co_presenter: current_user.presenter)
        sign_in current_user, scope: :user
      end

      it 'works' do
        post :accept_invitation, params: { id: session.id }

        expect(SessionInvitedImmersiveCoPresentership.last.status).to eq('accepted')
        expect(session.reload.co_presenters).to include(current_user.presenter)
      end
    end

    context 'when given completely free session' do
      let(:current_user) { create(:participant).user }

      it 'works' do
        sign_in current_user, scope: :user

        session = create(:completely_free_session)
        session.status = Session::Statuses::PUBLISHED
        session.save(validate: false)

        session.session_invited_immersive_participantships.create(participant: current_user.participant)

        post :accept_invitation, params: { id: session.id }

        expect(SessionInvitedImmersiveParticipantship.last.status).to eq('accepted')
        expect(session.reload.immersive_participants).to include(current_user.participant)
      end
    end

    context 'when given invited participant' do
      let(:current_user) { create(:participant).user }

      before do
        session.session_invited_immersive_participantships.create(participant: current_user.participant)
        sign_in current_user, scope: :user
      end

      it 'works' do
        post :accept_invitation, params: { id: session.id }

        expect(response).to redirect_to(preview_purchase_channel_session_path(session.slug,
                                                                              type: ObtainTypes::PAID_IMMERSIVE))
      end
    end

    context 'when given invited co-presenter' do
      let(:current_user) { create(:presenter).user }

      before do
        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter)
        sign_in current_user, scope: :user
      end

      it 'works' do
        post :accept_invitation, params: { id: session.id }

        expect(response).to redirect_to(session.relative_path)
      end
    end
  end

  describe 'GET :edit' do
    before { sign_in current_user, scope: :user }

    let(:immersive_session) do
      create(:immersive_session, duration: 15,
                                 immersive_type: Session::ImmersiveTypes::GROUP,
                                 immersive_access_cost: 12.99,
                                 min_number_of_immersive_and_livestream_participants: 2,
                                 max_number_of_immersive_participants: 10)
    end
    let(:channel) { immersive_session.channel }

    let(:current_user) { immersive_session.organizer }

    it 'does not fail' do
      get :edit, params: { channel_id: channel.slug, id: immersive_session.slug }
      expect(response).to be_successful
    end
  end

  describe 'POST :toggle_in_waiting_list' do
    let!(:session) do
      create(:published_session, min_number_of_immersive_and_livestream_participants: 2, max_number_of_immersive_participants: 2)
    end
    let(:current_user) { create(:user) }

    before do
      session.immersive_participants << create(:participant)
      session.immersive_participants << create(:participant)
      sign_in(current_user, scope: :user)
    end

    it 'works' do
      post :toggle_in_waiting_list, xhr: true, params: { channel_id: session.channel.id, id: session.id }

      expect(response).to be_successful

      expect(session.session_waiting_list.users).to include(current_user)
    end
  end

  describe 'POST :reject_invitation' do
    let(:session) { create(:published_session) }

    before do
      sign_in(current_user, scope: :user)
    end

    context 'when invited as co-presenter' do
      let(:current_user) { create(:presenter).user }

      before do
        session.session_invited_immersive_co_presenterships.create!(presenter: current_user.presenter)
      end

      it 'rejects pending co-presenter invitation' do
        post :reject_invitation, params: { id: session.id }

        expect(SessionInvitedImmersiveCoPresentership.first).to be_rejected
        expect(response).to redirect_to(sessions_participates_dashboard_path)
      end

      context 'when presenter promised to pay for invitee' do
        before do
          create(:organizer_session_pay_promise, abstract_session: session, co_presenter: current_user.presenter)
        end

        it 'cancels session pay promise' do
          expect do
            post :reject_invitation, params: { id: session.id }
          end.to change(OrganizerAbstractSessionPayPromise, :count).from(1).to(0)
        end
      end
    end

    context 'when invited as particiapnt' do
      let(:current_user) { create(:participant).user }

      before do
        session.session_invited_immersive_participantships.create(participant: current_user.participant)

        expect(SessionInvitedImmersiveParticipantship.count).to eq(1)
        expect(SessionInvitedImmersiveParticipantship.first).to be_pending

        post :reject_invitation, params: { id: session.id }
      end

      it 'rejects pending participant invitation' do
        expect(SessionInvitedImmersiveParticipantship.first).to be_rejected
        expect(response).to redirect_to(sessions_participates_dashboard_path)
      end
    end
  end

  describe 'POST :confirm_purchase' do
    describe 'when immersive participant' do
      before { sign_in current_user, scope: :user }

      context 'when given new free trial session' do
        let(:session) { create(:free_trial_immersive_session) }
        let(:current_user) { create(:participant).user }

        it 'works for first time participants' do
          post :confirm_purchase,
               params: { channel_id: session.channel.id, id: session.id, type: ObtainTypes::FREE_IMMERSIVE }

          expect(response).to be_redirect
          success = flash[:success] || flash[:success1] || flash[:success2] || flash[:success3] || flash[:success4] || flash[:success5]
          expect(success).to be_present
        end
      end

      context 'when given completely free session' do
        let(:session) do
          create(:completely_free_session).tap do |s|
            s.status = ::Session::Statuses::PUBLISHED; s.save!
          end
        end
        let(:current_user) { create(:participant).user }

        it 'works for first time participants' do
          post :confirm_purchase,
               params: { channel_id: session.channel.id, id: session.id, type: ObtainTypes::FREE_IMMERSIVE }

          expect(response).to be_redirect
          success = flash[:success] || flash[:success1] || flash[:success2] || flash[:success3] || flash[:success4] || flash[:success5]
          expect(success).to be_present
        end
      end
    end

    describe 'when livestream participant' do
      before { sign_in current_user, scope: :user }

      context 'when given new free trial session' do
        let!(:session) { create(:free_trial_livestream_session) }
        let(:current_user) { create(:participant).user }

        it 'works for first time participants' do
          post :confirm_purchase,
               params: { channel_id: session.channel.id, id: session.id, type: ObtainTypes::FREE_LIVESTREAM }

          expect(response).to be_redirect
          success = flash[:success] || flash[:success1] || flash[:success2] || flash[:success3] || flash[:success4] || flash[:success5]
          expect(success).to be_present
        end
      end
    end
  end

  describe 'GET :preview_cancel_modal' do
    render_views
    let(:session) { build(:immersive_session) }
    let(:current_user) { session.organizer }

    before do
      expect(SessionCreation.new(session: session,
                                 clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                                 ability: NullObject.new,
                                 invited_users_attributes: [],
                                 list_ids: []).execute).to be true
      sign_in current_user, scope: :user
    end

    it 'does not fail' do
      get :preview_cancel_modal, params: { id: session.id }, format: :js

      expect(response).to be_successful
    end
  end

  describe 'GET :preview_accept_invitation' do
    render_views
    let!(:session) { create(:published_session, immersive_access_cost: 25.11, livestream_access_cost: 21.11) }
    let(:current_user) { create(:participant).user }

    before do
      sign_in current_user, scope: :user
    end

    it 'does not fail' do
      session.session_invited_immersive_participantships.create(participant: current_user.participant)
      get :preview_accept_invitation, params: { id: session.id }, format: :js

      expect(response).to be_successful
    end
  end

  describe 'POST :cancel' do
    let(:session) { build(:immersive_session) }
    let(:current_user) { session.organizer }

    context 'when given existing valid session' do
      before do
        expect(SessionCreation.new(session: session,
                                   clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                                   ability: NullObject.new,
                                   invited_users_attributes: [],
                                   list_ids: []).execute).to be true
        expect(session.reload).not_to be_cancelled
        sign_in current_user, scope: :user
      end

      it 'cancels the session' do
        post :cancel,
             params: { id: session.id,
                       session: { abstract_session_cancel_reason_id: create(:abstract_session_cancel_reason).id } }

        expect(response).to be_redirect
        expect(session.reload).to be_cancelled
      end
    end
  end

  describe 'GET :preview_live_opt_out_modal' do
    render_views
    let(:current_user) { create(:participant).user }

    before do
      sign_in current_user, scope: :user
    end

    context 'when given completely free session' do
      let(:session) { create(:completely_free_session) }

      before do
        session.immersive_participants << current_user.participant
      end

      it 'does not fail' do
        get :preview_live_opt_out_modal, params: { id: session.id }, format: :js

        expect(response).to be_successful
      end
    end

    context 'when given session purchased with system credit' do
      let(:session) { create(:immersive_session) }

      before do
        session.immersive_participants << current_user.participant

        current_user.participant.system_credit_entries.create!(
          type: TransactionTypes::IMMERSIVE,
          commercial_document: session,
          amount: session.immersive_access_cost,
          description: 'does not matter'
        )
      end

      it 'does not fail' do
        get :preview_live_opt_out_modal, params: { id: session.id }, format: :js

        expect(response).to be_successful
      end
    end
  end

  describe 'GET :preview_vod_opt_out_modal' do
    render_views
    let(:current_user) { create(:participant).user }
    let(:session) { create(:immersive_session_with_recorded_delivery) }

    before do
      sign_in current_user, scope: :user
    end

    context 'when given vod session purchased with braintree' do
      before do
        session.recorded_members.create!(participant: current_user.participant, status: 'confirmed')
        create(:real_stripe_transaction, type: TransactionTypes::RECORDED, purchased_item: session, user: current_user)
      end

      it 'does not fail' do
        skip 'VOD opt outs are temporarily disabled'
        get :preview_vod_opt_out_modal, params: { id: session.id }, format: :js

        expect(response).to be_successful
      end
    end

    context 'when given session purchased with system credit' do
      before do
        session.recorded_members.create!(participant: current_user.participant, status: 'confirmed')

        current_user.participant.system_credit_entries.create!(
          type: TransactionTypes::RECORDED,
          commercial_document: session,
          amount: session.recorded_access_cost,
          description: 'does not matter'
        )
      end

      it 'does not fail' do
        skip 'VOD opt outs are temporarily disabled'
        get :preview_vod_opt_out_modal, params: { id: session.id }, format: :js

        expect(response).to be_successful
      end
    end
  end

  describe 'GET :ical' do
    render_views
    let(:session) { create(:immersive_session) }

    it 'works' do
      get :ical, params: { channel_id: session.channel_id, id: session.id }, format: :ics

      expect(response).to be_successful
    end
  end

  describe 'POST :live_opt_out_and_get_money_refund' do
    let(:session) { create(:immersive_session, start_at: 3.days.from_now.beginning_of_hour) }
    let(:current_user) { create(:participant).user }

    before { sign_in current_user, scope: :user }

    context 'when session participant' do
      it 'works' do
        session.immersive_participants << current_user.participant
        create(:real_stripe_transaction, type: TransactionTypes::IMMERSIVE, purchased_item: session, user: current_user)

        post :live_opt_out_and_get_money_refund, params: { id: session.id }

        expect(response).to be_redirect
        expect(PaymentTransaction.count).to eq(1)
        expect(PaymentTransaction.last.status).to eq(PaymentTransaction::Statuses::REFUND)
      end
    end
  end

  describe 'POST :vod_opt_out_and_get_money_refund' do
    let(:session) { create(:immersive_session, start_at: 3.days.from_now.beginning_of_hour) }
    let(:current_user) { create(:participant).user }

    before { sign_in current_user, scope: :user }

    context 'when session participant' do
      it 'works' do
        skip 'VOD opt outs are temporarily disabled'
        session.recorded_members.create!(participant: current_user.participant, status: 'confirmed')
        create(:real_stripe_transaction, type: TransactionTypes::RECORDED, purchased_item: session, user: current_user)

        post :vod_opt_out_and_get_money_refund, params: { id: session.id }

        expect(response).to be_redirect
        expect(PaymentTransaction.count).to eq(1)
        expect(PaymentTransaction.last.status).to eq(PaymentTransaction::Statuses::REFUND)
      end
    end
  end

  describe 'POST :vod_opt_out_without_money_refund' do
    let(:session) { create(:immersive_session_with_recorded_delivery, start_at: 3.days.from_now.beginning_of_hour) }
    let(:current_user) { create(:participant).user }

    before { sign_in current_user, scope: :user }

    context 'when session participant' do
      it 'works' do
        session.recorded_members.create!(participant: current_user.participant, status: 'confirmed')
        create(:real_stripe_transaction, type: TransactionTypes::RECORDED, purchased_item: session, user: current_user)

        expect(LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).count).to eq(0)

        post :vod_opt_out_without_money_refund, params: { id: session.id }

        expect(response).to be_redirect

        expect(LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).count).to eq(1)
        lt = LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).last
        expect(lt.data[:credit]).to eq(lt.amount)
      end
    end
  end

  describe 'POST :live_opt_out_without_money_refund' do
    context 'when given session that has to result in 100% sys credit refund' do
      let(:session) { create(:immersive_session, start_at: 3.days.from_now.beginning_of_hour) }
      let(:current_user) { create(:participant).user }

      before { sign_in current_user, scope: :user }

      context 'when session participant' do
        it 'works' do
          session.immersive_participants << current_user.participant
          create(:real_stripe_transaction, type: TransactionTypes::IMMERSIVE, purchased_item: session, user: current_user)

          expect(LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).count).to eq(0)

          post :live_opt_out_without_money_refund, params: { id: session.id }

          expect(response).to be_redirect

          expect(LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).count).to eq(1)
          lt = LogTransaction.where(type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).last
          expect(lt.data[:credit]).to eq(lt.amount)
        end
      end
    end

    context 'when given session which generates 50% sys credit refunds' do
      let(:session) { create(:free_trial_immersive_session, start_at: 6.hours.from_now.beginning_of_hour) }
      let(:current_user) { create(:participant).user }

      before { sign_in current_user, scope: :user }

      context 'when session participant' do
        it 'works' do
          session.immersive_participants << current_user.participant
          stripe_transaction = create(:real_stripe_transaction, type: TransactionTypes::IMMERSIVE, purchased_item: session, user: current_user)

          expect(IssuedSystemCredit.where(type: IssuedSystemCredit::Types::CHOSEN_REFUND).count).to eq(0)

          post :live_opt_out_without_money_refund, params: { id: session.id }

          expect(response).to be_redirect

          expect(IssuedSystemCredit.where(type: IssuedSystemCredit::Types::CHOSEN_REFUND).count).to eq(1)
          expect(IssuedSystemCredit.where(type: IssuedSystemCredit::Types::CHOSEN_REFUND).last.amount.to_f).to eq(stripe_transaction.amount * 0.5 / 100)
        end
      end
    end
  end

  describe '#compound_colors(number_of_lines)' do
    subject(:colors) { controller.compound_colors(number_of_lines) }

    let(:controller) { described_class.new }

    context 'when 1 line' do
      let(:number_of_lines) { 1 }

      it { expect(colors).to eq([controller.basic_compound_colors[0]]) }
    end

    context 'when 5 lines' do
      let(:number_of_lines) { 5 }

      it {
        expect(colors).to eq([
                               controller.basic_compound_colors[0],
                               controller.basic_compound_colors[1],
                               controller.basic_compound_colors[2],
                               controller.basic_compound_colors[3],
                               controller.basic_compound_colors[4]
                             ])
      }
    end

    context 'when 7 lines' do
      let(:number_of_lines) { 7 }

      it {
        expect(colors).to eq([
                               controller.basic_compound_colors[0],
                               controller.basic_compound_colors[1],
                               controller.basic_compound_colors[2],
                               controller.basic_compound_colors[3],
                               controller.basic_compound_colors[4],
                               controller.basic_compound_colors[0],
                               controller.basic_compound_colors[1]
                             ])
      }
    end
  end

  describe 'POST :request_another_time' do
    render_views
    before { sign_in(current_user, scope: :user) }

    let(:current_user) { create(:user) }
    let!(:session) { create(:immersive_session) }

    context 'when given valid request params' do
      it 'notifies about requested different time ' do
        valid_params = { 'start_at(1i)' => '2015',
                         'requested_at(2i)' => '5',
                         'requested_at(3i)' => '16',
                         'requested_at(4i)' => '04',
                         'requested_at(5i)' => '15',
                         delivery_method: 'livestream',
                         comment: 'zz' }

        post :request_another_time, params: {
          channel_id: session.channel.id,
          id: session.id,
          format: :js,
          session: valid_params.tap do |params|
            # has to work in all cases(notify with what we have)
            params.delete(:delivery_method) if [true, false].sample
          end
        }
        expect(response).to be_successful
        expect(flash.now[:success]).to be_present
      end
    end

    context 'when given invalid request params' do
      it 'notifies about requested different time ' do
        # NOTE: missing comment
        params = { 'start_at(1i)' => '2015',
                   'requested_at(2i)' => '5',
                   'requested_at(3i)' => '16',
                   'requested_at(4i)' => '04',
                   'requested_at(5i)' => '15',
                   delivery_method: 'livestream' }

        post :request_another_time, params: {
          channel_id: session.channel.id,
          id: session.id,
          format: :js,
          session: params
        }
        expect(response).to be_successful
        expect(flash.now[:success]).to be_blank
      end
    end
  end

  describe 'POST :publish' do
    before { sign_in(current_user, scope: :user) }

    context 'when given unpublished session of approved channel' do
      let(:current_user) { channel.organizer }
      let(:channel) { create(:listed_channel) }

      let!(:follower1_of_presenter) do
        create(:user).tap { |user| user.follow(session.organizer) }
      end

      let!(:subscriber1_of_chanenl) do
        create(:user).tap { |user| user.follow(channel) }
      end

      let!(:contact) { Contact.create!(for_user: create(:user), contact_user: session.organizer) }

      let!(:session) { create(:immersive_session, channel: channel, presenter: channel.organization.user.presenter) }

      before do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/whatever'
        expect(session).not_to be_published

        @notifications_before_publishing_count = Mailboxer::Notification.count
      end

      xit 'publishes' do
        post :publish, params: { channel_id: session.channel.id, id: session.id }

        expect(response).to be_redirect
        expect(session.reload).to be_published
      end

      # find all changes by TEMPORARYDISABLE
      xit 'notifies followers' do
        mailer = double
        expect(mailer).to receive(:deliver_later).at_least(:once)
        expect(SessionMailer).to receive(:published_session_from_user_you_follow).once.with(session.id,
                                                                                            follower1_of_presenter.id).and_return(mailer)

        mailer = double
        expect(mailer).to receive(:deliver_later).at_least(:once)
        expect(SessionMailer).to receive(:published_session_from_channel_you_follow).once.with(session.id,
                                                                                               subscriber1_of_chanenl.id).and_return(mailer)

        post :publish, params: { channel_id: session.channel.id, id: session.id }
      end

      xit 'notifies invited participants' do
        session.session_invited_immersive_participantships.create!(participant: create(:participant))

        expect(SessionInvitedImmersiveParticipantship.last.invitation_sent_at).to be_blank

        Sidekiq::Testing.inline! { post :publish, params: { channel_id: session.channel.id, id: session.id } }

        expect(SessionInvitedImmersiveParticipantship.last.invitation_sent_at).not_to be_blank
      end
    end
  end

  describe 'GET :ical' do
    before { sign_in current_user, scope: :user }

    let(:session) { create(:immersive_session) }
    let(:current_user) { nil }

    it 'works' do
      get :ical, params: { channel_id: session.channel.id, id: session.id }, format: :ics

      expect(response).to be_successful
    end
  end

  describe 'GET :modal_review' do
    context 'when given user allowed to rate' do
      before { sign_in current_user, scope: :user }

      let(:session) { create(:immersive_session).tap { |s| s.start_at = 1.day.ago; s.save(validate: false) } }
      let(:current_user) { create(:participant).user }

      before { session.immersive_participants << current_user.participant }

      it 'works' do
        get :modal_review, params: { channel_id: session.channel.id, id: session.id }, format: :js

        expect(response).to be_successful
      end
    end
  end

  describe 'GET :modal_live_participants_portal' do
    render_views
    let(:current_user) { session.organizer }
    let(:session) { create(:published_session) }
    let!(:contact) { Contact.create!(for_user: current_user, contact_user: create(:user)) }

    it 'works' do
      sign_in current_user, scope: :user

      session.session_invited_immersive_participantships.create!(participant: create(:participant))
      get :modal_live_participants_portal, xhr: true, params: { id: session.id }, format: :js
      expect(response).to be_successful
    end
  end
end
