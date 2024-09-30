# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::SessionsController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { 6.days.from_now }
    let(:outside_timerange1) { 1.day.from_now }
    let(:outside_timerange2) { 12.days.from_now }
    let(:user) { create(:user, display_name: "#{search_query} Sedan", created_at: inside_timerange) }
    let(:presenter) { create(:presenter, user: user) }
    let(:organization) { create(:organization, user: presenter.user) }
    let(:presentership) do
      create(:channel_invited_presentership, presenter: presenter, channel: create(:listed_channel))
    end
    let(:channel_match_in_title) do
      create(:listed_channel, title: "Channel match in title #{search_query} Baklazhan", created_at: inside_timerange)
    end
    let(:listed_channel) { create(:listed_channel, organization: organization) }
    let(:channel_match_in_organization_user) do
      create(:listed_channel, title: 'Channel match in organization user', organization: organization,
                              created_at: outside_timerange2).reload
    end
    let(:channel_with_no_match) { create(:listed_channel, title: 'Channel with no match') }
    let(:session1) do
      create(:session_with_livestream_only_delivery,
             title: 'Session match in channel organizer duration 15', presenter: organization.user.presenter, duration: 15,
             channel: channel_match_in_organization_user, created_at: inside_timerange, start_at: inside_timerange, status: ::Session::Statuses::PUBLISHED)
    end
    let(:session2) do
      create(:session_with_livestream_only_delivery,
             title: "Session match in title duration 25 #{search_query}", presenter: listed_channel.organizer.presenter,
             duration: 25, channel: listed_channel, created_at: outside_timerange1, start_at: outside_timerange1, status: ::Session::Statuses::PUBLISHED)
    end
    let(:free_session) do
      create(:completely_free_session,
             title: 'Session match in presenter 2 duration 25', presenter: listed_channel.organization.user.presenter, channel: listed_channel,
             duration: 25, livestream_purchase_price: 0, created_at: outside_timerange2, start_at: outside_timerange2, status: ::Session::Statuses::PUBLISHED)
    end
    let(:paid_session_with_no_match) do
      create(:livestream_session,
             channel: create(:listed_channel), title: 'Session no match duration 20 private', duration: 20, livestream_purchase_price: 12.99,
             created_at: inside_timerange, start_at: inside_timerange, status: ::Session::Statuses::PUBLISHED)
    end
    let(:relevant_models) { [session1, free_session] }
    let(:irrelevant_models) { [paid_session_with_no_match] }
    let(:all_models) { relevant_models + irrelevant_models }
    let(:free_models) { [free_session] }
    let(:paid_models) { [paid_session_with_no_match] }
    let(:models_inside_interval) { [session1, paid_session_with_no_match] }
    let(:models_outside_interval) { [session2, free_session] }

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
          expect(response_body['response']['sessions']).to have(1).items
          expect(response_body['pagination']['limit']).to be(1)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 100 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end
      end

      context 'when given query param' do
        it 'returns relevant models' do
          relevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end

        it 'does not return irrelevant models' do
          irrelevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_session(model))
          end
        end

        context 'when given search_by param set to "title"' do
          let(:title_search_query) { 'avada kedavra' }
          let(:session_match_in_title_only) do
            create(:session_with_livestream_only_delivery, title: "session match in title only #{title_search_query}")
          end
          let(:session_match_description_only) do
            create(:session_with_livestream_only_delivery,
                   description: "session match in description only #{title_search_query}")
          end

          it 'returns session with match in title' do
            session_match_in_title_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).to include(pattern_search_api_session(session_match_in_title_only))
          end

          it 'does not return session with match not in title' do
            session_match_description_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).not_to include(pattern_search_api_session(session_match_description_only))
          end
        end
      end

      context 'when given duration params' do
        it 'returns relevant models' do
          free_session.update_pg_search_document
          session2.update_pg_search_document
          paid_session_with_no_match.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          [free_session, session2, paid_session_with_no_match].each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end

        it 'does not return irrelevant models' do
          session1.update_pg_search_document
          get :index, format: :json, params: { duration_from: 20 * 60, duration_to: 25 * 60 }
          response_body = JSON.parse(response.body)
          expect(response_body).not_to include(pattern_search_api_session(session1))
        end
      end

      context 'when given free param set to true' do
        it 'returns free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end

        it 'does not return paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: true }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_session(model))
          end
        end
      end

      context 'when given free param set to false' do
        it 'returns paid models' do
          paid_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          paid_models.each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end

        it 'does not return free models' do
          free_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { free: false }
          response_body = JSON.parse(response.body)
          free_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_session(model))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 3.days.from_now, created_before: 9.days.from_now }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api_session(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: 3.days.from_now, created_before: 9.days.from_now }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api_session(model))
          end
        end
      end
    end
  end
end
