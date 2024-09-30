# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::VideosController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { '01-06-2019'.to_datetime }
    let(:outside_timerange1) { '01-01-2019'.to_datetime }
    let(:outside_timerange2) { '31-12-2019'.to_datetime }
    let(:user) { create(:user, display_name: "#{search_query} Sedan", created_at: inside_timerange) }
    let(:presenter) { create(:presenter, user: user) }
    let(:organization) { create(:organization, user: presenter.user) }
    let(:listed_channel) { create(:listed_channel) }
    let(:channel_match_in_organizer) do
      create(:listed_channel, title: 'Listed Channel', organization: organization, created_at: outside_timerange1)
    end
    let(:session) do
      create(:session_with_livestream_only_delivery, title: "Session match in title duration 25 #{search_query}",
                                                     presenter: listed_channel.organization.user.presenter, duration: 25, channel: listed_channel, created_at: outside_timerange1)
    end
    let(:free_session) do
      create(:completely_free_session, title: 'Session match in presenter 2 duration 25', presenter: presenter,
                                       channel: channel_match_in_organizer, duration: 25, recorded_purchase_price: 0, recorded_free: true, created_at: outside_timerange2)
    end
    let(:video1) do
      create(:video, room: session.room, duration: 22 * 60 * 1000, created_at: inside_timerange, show_on_profile: true,
                     published: inside_timerange)
    end
    let(:video2) do
      create(:seed_video, room: session.room, duration: 30 * 60 * 1000, created_at: outside_timerange1,
                          show_on_profile: true, published: outside_timerange1)
    end
    let(:free_video) do
      create(:video, room: free_session.room, created_at: outside_timerange1, show_on_profile: true,
                     published: outside_timerange1)
    end
    let(:video_with_no_match) { create(:video, show_on_profile: true, published: inside_timerange) }
    let(:relevant_models) { [video1, video2] }
    let(:irrelevant_models) { [video_with_no_match] }
    let(:all_models) { relevant_models + irrelevant_models }
    let(:free_models) { [free_video] }
    let(:models_inside_interval) { [video1] }
    let(:models_outside_interval) { [video2, free_video] }

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
        before do
          all_models.each(&:update_pg_search_document)
        end

        it 'contains only limited number of entities' do
          all_models
          get :index, format: :json, params: { limit: 3 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['videos']).to have(3).items
          expect(response_body['pagination']['limit']).to be(3)
        end
      end

      context 'when limit is increased' do
        before do
          all_models.each(&:update_pg_search_document)
        end

        it 'contains all entities' do
          all_models
          get :index, format: :json, params: { limit: 100 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api_video(model))
          end
        end
      end

      context 'when given query param' do
        before do
          relevant_models.each(&:update_pg_search_document)
        end

        it 'returns relevant models' do
          relevant_models
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api_video(model))
          end
        end

        it 'does not return irrelevant models' do
          irrelevant_models
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_video(model))
          end
        end

        context 'when given search_by param set to "title"' do
          let(:title_search_query) { 'avada kedavra' }
          let(:video_match_in_title_only) do
            video = create(:video_published_on_listed_channel)
            video.title = "Video match in title only #{title_search_query}"
            video.save
            video
          end
          let(:video_match_description_only) do
            create(:video_published_on_listed_channel,
                   description: "video match in description only #{title_search_query}")
          end

          it 'returns video with match in title' do
            video_match_in_title_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).to include(pattern_search_api_video(video_match_in_title_only))
          end

          it 'does not return video with match not in title' do
            all_models.each(&:update_pg_search_document)
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).not_to include(pattern_search_api_video(video_match_description_only))
          end
        end
      end

      context 'when given duration params' do
        it 'returns relevant models' do
          all_models
          video1.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          expect(response_body).to include(pattern_search_api_video(video1))
        end

        it 'does not return irrelevant models' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          expect(response_body).not_to include(pattern_search_api_video(video2))
        end
      end

      context 'when given free param set to true' do
        it 'returns free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).to include(pattern_search_api_video(model))
          end
        end
      end

      context 'when given free param set to false' do
        it 'does not return free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_video(model))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api_video(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api_video(model))
          end
        end
      end
    end
  end
end
