# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::SearchController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { 15.days.from_now }
    let(:outside_timerange1) { 1.day.from_now }
    let(:outside_timerange2) { 30.days.from_now }
    let(:presenter1) do
      create(:presenter, user: create(:user, display_name: "#{search_query} Sedan", created_at: inside_timerange))
    end
    let(:presenter2) do
      create(:presenter, user: create(:user, display_name: "#{search_query} 2", created_at: inside_timerange))
    end
    let(:presenter3) { create(:presenter, user: create(:user, created_at: outside_timerange1)) }
    let(:organization1) { create(:organization, user: presenter1.user) }
    let(:organization2) { create(:organization, user: presenter2.user) }
    let(:organization3) { create(:organization, user: presenter3.user) }
    let(:listed_channel1) { create(:listed_channel, organization: organization1) }
    let(:listed_channel2) { create(:listed_channel, organization: organization2) }
    let(:listed_channel3) { create(:listed_channel, organization: organization3) }
    let(:user) { listed_channel1.organization.user }
    let(:user2) { listed_channel2.organization.user }
    let(:user_with_no_match) { listed_channel3.organizer }
    let(:presentership) { create(:channel_invited_presentership, presenter: presenter1, channel: listed_channel2) }
    let(:channel_match_in_title) do
      channel_match_in_title = create(:listed_channel, title: "Channel match in title #{search_query} Baklazhan", created_at: inside_timerange)
      channel_match_in_title.update(listed_at: inside_timerange)
      channel_match_in_title
    end
    let(:channel_match_in_presenter) do
      create(:listed_channel, title: 'Listed Channel', organization: organization1, created_at: outside_timerange1)
    end
    let!(:channel_match_in_presentership) do
      channel = presentership.channel.reload
      channel.title = 'Presentership Channel'
      channel.save
      channel
    end
    let(:channel_match_in_organization_user) do
      create(:listed_channel, title: 'Channel match in organization user', organization: organization2,
                              created_at: outside_timerange2).reload
    end
    let(:channel_with_no_match) { create(:listed_channel, title: 'Channel with no match') }
    let(:session1) do
      create(:session_with_livestream_only_delivery,
             title: 'Session match in presenter duration 15', presenter: presenter1, duration: 15, channel: channel_match_in_presenter,
             created_at: inside_timerange, start_at: inside_timerange, status: Session::Statuses::PUBLISHED)
    end
    let(:session2) do
      create(:session_with_livestream_only_delivery,
             title: "Session match in title duration 25 #{search_query}", presenter: presenter1, duration: 25, channel: channel_match_in_presenter,
             created_at: outside_timerange1, start_at: outside_timerange1, status: Session::Statuses::PUBLISHED)
    end
    let(:free_session) do
      create(:completely_free_session,
             title: 'Session match in presenter 2 duration 25', presenter: presenter2, channel: listed_channel2, duration: 25,
             livestream_purchase_price: 0, recorded_purchase_price: 0, recorded_free: true, created_at: outside_timerange2, start_at: outside_timerange2, status: Session::Statuses::PUBLISHED)
    end
    let(:paid_session_with_no_match) do
      create(:livestream_session,
             title: 'Session no match duration 20 private', duration: 20, channel: create(:listed_channel), livestream_purchase_price: 12.99,
             recorded_purchase_price: 12.99, created_at: inside_timerange, start_at: inside_timerange, status: Session::Statuses::PUBLISHED)
    end
    let(:video1) do
      create(:video, room: session2.room, duration: 22 * 60 * 1000, created_at: inside_timerange, show_on_profile: true,
                     published: inside_timerange)
    end
    let(:video2) do
      create(:seed_video, room: session2.room, duration: 15 * 60 * 1000, created_at: outside_timerange1,
                          show_on_profile: true, published: outside_timerange1)
    end
    let(:free_video) do
      create(:video, room: free_session.room, created_at: outside_timerange1, show_on_profile: true,
                     published: outside_timerange1)
    end
    let(:paid_video) do
      create(:video, room: paid_session_with_no_match.room, created_at: inside_timerange, show_on_profile: true,
                     published: inside_timerange)
    end
    let(:video_with_no_match) { create(:video, show_on_profile: true, published: inside_timerange) }
    let(:video_with_error) do
      create(:video_with_error, created_at: inside_timerange, show_on_profile: true, published: inside_timerange)
    end
    let(:recording_match_in_title) { create(:recording_published, title: "Test Recording #{search_query}") }
    let(:recording_match_in_description) { create(:recording_published, description: "Test Recording #{search_query}") }
    let(:recording_match_in_channel) { create(:recording_published, channel: channel_match_in_title) }
    let(:recording_with_no_match) { create(:recording_published) }
    let(:relevant_models) do
      [
        user,
        channel_match_in_title,
        channel_match_in_presenter,
        channel_match_in_presentership,
        channel_match_in_organization_user,
        session1,
        free_session,
        video1,
        video2,
        recording_match_in_title,
        recording_match_in_description,
        recording_match_in_channel
      ]
    end
    let(:irrelevant_models) do
      [
        user_with_no_match,
        channel_with_no_match,
        paid_session_with_no_match,
        video_with_no_match,
        recording_with_no_match
      ]
    end
    let!(:all_models) { relevant_models + irrelevant_models }
    let(:free_models) { [free_video, free_session] }
    let(:paid_models) { [paid_video, paid_session_with_no_match] }
    let(:models_inside_interval) do
      [
        user,
        channel_match_in_title,
        session1,
        paid_session_with_no_match,
        video1,
        paid_video
      ]
    end
    let(:models_outside_interval) do
      [
        user_with_no_match,
        channel_match_in_presenter,
        session2,
        video2,
        free_video,
        channel_match_in_organization_user,
        free_session
      ]
    end

    describe 'GET index:' do
      context 'when given no params' do
        it 'is successful and contains valid json' do
          get :index, format: :json
          expect(response).to be_successful
          expect do
            JSON.parse(response.body)
          end.not_to raise_error, response.body
        end
      end

      context 'when limit is set' do
        it 'contains only limited number of entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 5 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['documents']).to have(5).items
          expect(response_body['pagination']['limit']).to be(5)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 100 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end
      end

      context 'when given query param' do
        it 'returns relevant models' do
          relevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query, limit: 100 }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return irrelevant models' do
          irrelevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api(model))
          end
        end
      end

      context 'when given duration params' do
        it 'returns relevant models' do
          video1.update_pg_search_document
          free_session.update_pg_search_document
          session2.update_pg_search_document
          paid_session_with_no_match.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          [video1, free_session, session2, paid_session_with_no_match].each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return irrelevant models' do
          video2.update_pg_search_document
          session1.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          [video2, session1].each do |model|
            expect(response_body).not_to include(pattern_search_api(model))
          end
        end
      end

      context 'when given free param set to true' do
        it 'returns free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).not_to include(pattern_search_api(model))
          end
        end
      end

      context 'when given free param set to false' do
        it 'returns paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).not_to include(pattern_search_api(model))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 10.days.from_now, created_before: 20.days.from_now }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 10.days.from_now, created_before: 20.days.from_now }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api(model))
          end
        end
      end

      context 'when given search_by param set to "title"' do
        let(:title_search_query) { 'avada kedavra' }
        let(:user_match_in_title_only) do
          user = create(:listed_channel).organizer
          user.public_display_name_source = 'display_name'
          user.display_name = title_search_query.to_s
          user.save
          user
        end
        let(:channel_match_in_title_only) do
          create(:listed_channel, title: "Channel match in title only #{title_search_query}")
        end
        let(:session_match_in_title_only) do
          create(:published_session, title: "Session match in title only #{title_search_query}")
        end
        let(:video_match_in_title_only) do
          video = create(:video_published_on_listed_channel)
          video.title = "Video match in title only #{title_search_query}"
          video.save
          video
        end
        let(:recording_match_in_title_only) do
          create(:recording_published, title: "Recording match in title only #{title_search_query}")
        end
        let(:models_with_match_only_in_title) do
          [
            user_match_in_title_only,
            channel_match_in_title_only,
            session_match_in_title_only,
            video_match_in_title_only,
            recording_match_in_title_only
          ]
        end
        let(:channel_match_description_only) do
          create(:listed_channel, description: "Channel match in description only #{title_search_query}")
        end

        it 'returns models with match in title' do
          models_with_match_only_in_title.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
          response_body = JSON.parse(response.body)
          models_with_match_only_in_title.each do |model|
            expect(response_body).to include(pattern_search_api(model))
          end
        end

        it 'does not return models with match not in title' do
          channel_match_description_only.update_pg_search_document
          get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
          response_body = JSON.parse(response.body)
          expect(response_body).not_to include(pattern_search_api(channel_match_description_only))
        end

        context 'when promo_weight is used' do
          before do
            all_models.each(&:update_pg_search_document)
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title', promo_weight: 1 }
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end
      end
    end
  end
end
