# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::RecordingsController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { '01-06-2019'.to_datetime }
    let(:outside_timerange2) { '31-12-2019'.to_datetime }
    let(:channel_match_in_title) do
      create(:listed_channel, title: "Channel match in title #{search_query} Baklazhan", created_at: inside_timerange)
    end
    let(:recording_match_in_title) { create(:recording_published, title: "Test Recording #{search_query}") }
    let(:recording_match_in_description) { create(:recording_published, description: "Test Recording #{search_query}") }
    let(:recording_match_in_channel) { create(:recording_published, channel: channel_match_in_title) }
    let(:recording_with_no_match) { create(:recording_published) }
    let(:free_recording) do
      create(:recording_published, duration: 23 * 60 * 1000, purchase_price: 0, created_at: inside_timerange,
                                   published: inside_timerange)
    end
    let(:paid_recording) do
      create(:recording_published, duration: 33 * 60 * 1000, purchase_price: 4.99, created_at: outside_timerange2,
                                   published: outside_timerange2)
    end
    let(:relevant_models) do
      [
        recording_match_in_title,
        recording_match_in_description,
        recording_match_in_channel
      ]
    end
    let(:irrelevant_models) { [recording_with_no_match, free_recording, paid_recording] }
    let(:all_models) { relevant_models + irrelevant_models }
    let(:free_models) { [free_recording] }
    let(:paid_models) { [paid_recording] }
    let(:models_inside_interval) { [free_recording] }
    let(:models_outside_interval) { [paid_recording] }

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
          get :index, format: :json, params: { limit: 2 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['recordings']).to have(2).items
          expect(response_body['pagination']['limit']).to be(2)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 100 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end
      end

      context 'when given query param' do
        it 'returns relevant models' do
          relevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end

        it 'does not return irrelevant models' do
          irrelevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_recording(model))
          end
        end

        context 'when given search_by param set to "title"' do
          let(:title_search_query) { 'avada kedavra' }
          let(:recording_match_in_title_only) do
            create(:recording_published, title: "Recording match in title only #{title_search_query}")
          end
          let(:recording_match_description_only) do
            create(:recording_published, description: "Recording match in description only #{title_search_query}")
          end

          it 'returns recording with match in title' do
            recording_match_in_title_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).to include(pattern_search_api_recording(recording_match_in_title_only))
          end

          it 'does not return recording with match not in title' do
            recording_match_description_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).not_to include(pattern_search_api_recording(recording_match_description_only))
          end
        end
      end

      context 'when given duration params' do
        it 'returns relevant models' do
          free_recording.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          [free_recording].each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end

        it 'does not return irrelevant models' do
          paid_recording.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          [paid_recording].each do |model|
            expect(response_body).not_to include(pattern_search_api_recording(model))
          end
        end
      end

      context 'when given free param set to true' do
        it 'returns free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end

        it 'does not return paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_recording(model))
          end
        end
      end

      context 'when given free param set to false' do
        it 'returns paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end

        it 'does not return free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_recording(model))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api_recording(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api_recording(model))
          end
        end
      end
    end
  end
end
