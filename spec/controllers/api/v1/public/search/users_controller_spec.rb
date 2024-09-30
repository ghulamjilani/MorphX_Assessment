# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::UsersController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { 6.months.ago }
    let(:outside_timerange1) { 12.months.ago }
    let(:presenter) do
      create(:presenter, user: create(:user, display_name: "#{search_query} Sedan", created_at: inside_timerange))
    end
    let(:presenter2) do
      create(:presenter,
             user: create(:user, first_name: 'John', last_name: 'Doe', display_name: 'John Doe',
                                 created_at: outside_timerange1))
    end
    let(:organization) { create(:organization, user: presenter.user) }
    let(:organization2) { create(:organization, user: presenter2.user) }
    let(:listed_channel) { create(:listed_channel, organization: organization) }
    let(:listed_channel2) { create(:listed_channel, organization: organization2) }
    let(:user) { listed_channel.organizer }
    let(:user_with_no_match) { listed_channel2.organizer }
    let(:user_with_no_match) { listed_channel2.organizer }
    let(:relevant_models) { [user] }
    let(:irrelevant_models) { [user_with_no_match] }
    let!(:all_models) { relevant_models + irrelevant_models }
    let(:models_inside_interval) { [user] }
    let(:models_outside_interval) { [user_with_no_match] }

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
          get :index, format: :json, params: { limit: 1 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['users']).to have(1).item
          expect(response_body['pagination']['limit']).to be(1)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 10 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api_user(model))
          end
        end
      end

      context 'when given query param' do
        let(:title_search_query) { 'avada kedavra' }
        let(:user_match_in_title_only) do
          user = create(:listed_channel).organizer
          user.public_display_name_source = 'display_name'
          user.display_name = title_search_query.to_s
          user.save
          user
        end
        let(:user_with_listed_channel) { create(:listed_channel).organizer }
        let(:user_account_match_in_bio) do
          ua = create(:user_account, bio: title_search_query, user: user_with_listed_channel)
          ua.user.update_pg_search_document
          ua
        end
        let(:user_match_in_bio_only) { user_account_match_in_bio.user }

        it 'returns relevant models' do
          relevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api_user(model))
          end
        end

        it 'returns user with match in bio' do
          user_match_in_bio_only.update_pg_search_document
          get :index, format: :json, params: { query: title_search_query }
          response_body = JSON.parse(response.body)
          expect(response_body).to include(pattern_search_api_user(user_match_in_bio_only))
        end

        it 'does not return irrelevant models' do
          irrelevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_user(model))
          end
        end

        context 'when given search_by param set to "title"' do
          it 'returns user with match in title' do
            user_match_in_title_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).to include(pattern_search_api_user(user_match_in_title_only))
          end

          it 'does not return user with match not in display name' do
            user_match_in_bio_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).not_to include(pattern_search_api_user(user_match_in_bio_only))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 9.months.ago, created_before: 3.months.ago }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api_user(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 9.months.ago, created_before: 3.months.ago }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api_user(model))
          end
        end
      end
    end
  end
end
