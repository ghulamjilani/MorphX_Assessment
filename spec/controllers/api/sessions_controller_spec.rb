# frozen_string_literal: true

require 'spec_helper'

describe Api::SessionsController do
  describe 'Session creation part. ' do
    render_views
    before do
      request.headers['Accept']       = 'application/json'
      request.headers['X-User-ID']    = current_user.id
      request.headers['X-User-Token'] = current_user.authentication_token
    end

    context 'when Get session pre-settings' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      before do
        create(:custom_description_field_label)
      end

      it 'returns json' do
        get :new, params: { channel_id: channel.id }
        expect(JSON.parse(response.body)['status']).to eq(200)
      end
    end
    # "{\"status\":200,\"response\":{\"session\":{\"adult\":null,\"age_restrictions\":0,\"custom_description_field_label\":\"Agenda\",\"description\":\"x yx yx y\",\"duration\":30,
    # \"free_trial_for_first_time_participants\":false,\"immersive_free\":false,\"immersive_access_cost\":null,\"immersive_free_trial\":false,\"immersive_free_slots\":null,\"immersive_type\":\"group\",\"level\":\"All Levels\",
    # \"livestream_free\":true,\"livestream_access_cost\":0,\"livestream_free_trial\":false,\"livestream_free_slots\":null,\"max_number_of_immersive_participants\":5,\"min_number_of_immersive_and_livestream_participants\":2,
    # \"pre_time\":0,\"presenter_id\":null,\"private\":false,\"publish_after_requested_free_session_is_satisfied_by_admin\":null,\"recorded_free\":true,\"recorded_access_cost\":0,\"requested_free_session_reason\":null,
    # \"custom_description_field_value\":null,\"start_at\":\"2017-07-07T04:00:00.000+06:00\",\"start_now\":false,\"autostart\":false,\"service_type\":\"vidyo\",
    # \"title\":\"Gary Jackson Test Channel #1 Live Session\",\"twitter_feed_title\":null}}}"

    context 'when Create the session' do
      let(:organization) { create(:organization_with_subscription) }
      let(:current_user) { organization.user }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:ffmpegservice_account) { create(:ffmpegservice_account, organization_id: organization.id) }
      let(:ffmpegservice_account2) { create(:ffmpegservice_account, organization_id: nil) }

      before do
        current_user.presenter.presenter_credit_entries.create!(
          amount: 99,
          description: 'Fake spending to make test pass'
        )
        ffmpegservice_account
        ffmpegservice_account2
      end

      it 'returns json' do
        post :create, params: { channel_id: channel.id, session: {
          clicked_button_type: 'published',
          adult: false,
          age_restrictions: 0,
          custom_description_field_label: 'Agenda',
          description: Forgery(:lorem_ipsum).paragraphs(3),
          duration: 30,
          free_trial_for_first_time_participants: false,
          immersive_free: false,
          immersive_access_cost: nil,
          immersive_free_trial: false,
          immersive_free_slots: nil,
          immersive_type: 'group',
          level: 'All Levels',
          livestream_free: true,
          livestream_access_cost: 0,
          livestream_free_trial: false,
          livestream_free_slots: nil,
          max_number_of_immersive_participants: 5,
          min_number_of_immersive_and_livestream_participants: 2,
          pre_time: 0,
          presenter_id: nil,
          private: false,
          publish_after_requested_free_session_is_satisfied_by_admin: nil,
          recorded_free: true,
          recorded_access_cost: 0,
          requested_free_session_reason: nil,
          custom_description_field_value: nil,
          start_at: (Time.now.utc + 30.minutes),
          start_now: true,
          autostart: false,
          service_type: 'vidyo',
          title: 'Gary Jackson Test Channel #1 Live Session',
          twitter_feed_title: nil
        } }
        expect(JSON.parse(response.body)['status']).to eq(201)
      end
    end

    context 'when Update the session' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.user }
      let(:presenter) { current_user.presenter }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: presenter) }

      before do
        current_user.presenter.presenter_credit_entries.create!(
          amount: 99,
          description: 'Fake spending to make test pass'
        )
      end

      it 'returns validate error json' do
        patch :update, params: { channel_id: channel.id, id: session.id, session: {
          clicked_button_type: 'published',
          adult: false,
          age_restrictions: 0,
          custom_description_field_label: 'Agenda',
          description: Forgery(:lorem_ipsum).paragraphs(3),
          duration: 30,
          free_trial_for_first_time_participants: false,
          immersive_free: false,
          immersive_access_cost: nil,
          immersive_free_trial: false,
          immersive_free_slots: nil,
          immersive_type: 'group',
          level: 'All Levels',
          livestream_free: true,
          livestream_access_cost: 0,
          livestream_free_trial: false,
          livestream_free_slots: nil,
          max_number_of_immersive_participants: 5,
          min_number_of_immersive_and_livestream_participants: 2,
          pre_time: 0,
          presenter_id: nil,
          private: false,
          publish_after_requested_free_session_is_satisfied_by_admin: nil,
          recorded_free: true,
          recorded_access_cost: 0,
          requested_free_session_reason: nil,
          custom_description_field_value: nil,
          start_at: (Time.now.utc - 1.day),
          start_now: false,
          autostart: false,
          service_type: 'vidyo',
          title: 'Gary Jackson Test Channel #1 Live Session',
          twitter_feed_title: nil
        } }
        expect(JSON.parse(response.body)['status']).to eq(422)
      end

      it 'returns json' do
        patch :update, params: { channel_id: channel.id, id: session.id, session: {
          adult: false, age_restrictions: 0,
          custom_description_field_label: 'Agenda',
          description: Forgery(:lorem_ipsum).paragraphs(3),
          duration: 30,
          free_trial_for_first_time_participants: false,
          immersive_free: false,
          immersive_access_cost: nil,
          immersive_free_trial: false,
          immersive_free_slots: nil,
          immersive_type: 'group',
          level: 'All Levels',
          livestream_free: true,
          livestream_access_cost: 0,
          livestream_free_trial: false,
          livestream_free_slots: nil,
          max_number_of_immersive_participants: 5,
          min_number_of_immersive_and_livestream_participants: 2,
          private: false,
          publish_after_requested_free_session_is_satisfied_by_admin: nil,
          recorded_free: true,
          recorded_access_cost: 0,
          requested_free_session_reason: nil,
          custom_description_field_value: nil,
          autostart: false,
          service_type: 'vidyo',
          title: 'Gary Jackson Test Channel #xxxx1 Live Session',
          twitter_feed_title: nil
        } }
        expect(JSON.parse(response.body)['status']).to eq(202)
      end
    end
  end

  describe 'POST :confirm_purchase' do
    describe 'when immersive participant' do
      before do
        request.headers['X-User-ID']    = current_user.id
        request.headers['X-User-Token'] = current_user.authentication_token
      end

      context 'when given new free trial session' do
        let(:session) { create(:free_trial_immersive_session) }
        let(:current_user) { create(:participant).user }

        it 'works for first time participants' do
          post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_IMMERSIVE }
          expect(JSON.parse(response.body)['status']).to eq(200)
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
          post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_IMMERSIVE }
          expect(JSON.parse(response.body)['status']).to eq(200)
        end
      end
    end

    describe 'when livestream participant' do
      before do
        request.headers['X-User-ID']    = current_user.id
        request.headers['X-User-Token'] = current_user.authentication_token
      end

      context 'when given new free trial session' do
        let!(:session) { create(:free_trial_livestream_session) }
        let(:current_user) { create(:participant).user }

        it 'works for first time participants' do
          post :confirm_purchase, params: { id: session.id, type: ObtainTypes::FREE_LIVESTREAM }
          expect(JSON.parse(response.body)['status']).to eq(200)
        end
      end
    end

    describe 'when PAID and system_credit_balance methods' do
      before do
        request.headers['X-User-ID']    = current_user.id
        request.headers['X-User-Token'] = current_user.authentication_token
        allow_any_instance_of(User).to receive(:system_credit_balance).and_return(999)
      end

      context 'when given new session' do
        let!(:session) { create(:session_with_livestream_only_delivery) }
        let(:current_user) { create(:participant).user }

        it 'works for paid livestream participants' do
          post :confirm_purchase, params: { id: session.id, type: ObtainTypes::PAID_LIVESTREAM }
          expect(JSON.parse(response.body)['status']).to eq(200)
        end
      end

      context 'works for paid vods participants' do
        let!(:session) { create(:recorded_session) }
        let(:current_user) { create(:participant).user }

        it 'works for participants' do
          post :confirm_purchase, params: { id: session.id, type: ObtainTypes::PAID_VOD }
          expect(JSON.parse(response.body)['status']).to eq(200)
        end
      end

      context 'works for paid immersive participants' do
        let!(:session) { create(:published_session) }
        let(:current_user) { create(:participant).user }

        it 'works for participants' do
          post :confirm_purchase,
               params: { id: session.id,
                         type: ObtainTypes::PAID_IMMERSIVE,
                         stripe_token: @stripe_test_helper.generate_card_token,
                         country: 'US',
                         zip: '60000' }
          expect(JSON.parse(response.body)['status']).to eq(200)
        end
      end
    end
  end
end
