# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::ChannelsController do
  render_views

  describe '.json request format' do
    let(:search_query) { 'Some Random Searchquery' }
    let(:inside_timerange) { '01-06-2019'.to_datetime }
    let(:outside_timerange1) { '01-01-2019'.to_datetime }
    let(:outside_timerange2) { '31-12-2019'.to_datetime }
    let(:user) { create(:user, display_name: "#{search_query} Sedan", created_at: inside_timerange) }
    let(:user_with_no_match) { create(:user, created_at: outside_timerange1) }
    let(:presenter) { create(:presenter, user: user) }
    let(:organization) { create(:organization, user: user) }
    let(:presentership) do
      create(:channel_invited_presentership_accepted, presenter: presenter, channel: create(:listed_channel))
    end
    let(:channel_match_in_title) do
      channel = create(:approved_channel, title: "Channel match in title #{search_query} Baklazhan")
      channel.update(listed_at: inside_timerange)
      channel
    end
    let(:channel_match_in_presenter) do
      create(:listed_channel, title: 'Listed Channel', presenter: presenter, created_at: outside_timerange1)
    end
    let!(:channel_match_in_presentership) do
      channel = presentership.channel.reload
      channel.title = 'Presentership Channel'
      channel.save
      channel
    end
    let(:channel_match_in_organization_user) do
      create(:listed_channel, title: 'Channel match in organization user', organization: organization,
                              created_at: outside_timerange2).reload
    end
    let(:channel_with_no_match) { create(:listed_channel, title: 'Channel with no match') }
    let(:relevant_models) do
      [
        channel_match_in_title,
        channel_match_in_presenter,
        channel_match_in_presentership,
        channel_match_in_organization_user
      ]
    end
    let(:irrelevant_models) { [channel_with_no_match] }
    let(:all_models) { relevant_models + irrelevant_models }
    let(:models_inside_interval) { [channel_match_in_title] }
    let(:models_outside_interval) { [channel_match_in_presenter, channel_match_in_organization_user] }

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
          get :index, format: :json, params: { limit: 3 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['channels']).to have(3).items
          expect(response_body['pagination']['limit']).to be(3)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { limit: 100 }
          response_body = JSON.parse(response.body)
          all_models.each do |model|
            expect(response_body).to include(pattern_search_api_channel(model))
          end
        end
      end

      context 'when given query param' do
        it 'returns relevant models' do
          relevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          relevant_models.each do |model|
            expect(response_body).to include(pattern_search_api_channel(model))
          end
        end

        it 'does not return irrelevant models' do
          irrelevant_models.each(&:update_pg_search_document)
          get :index, format: :json, params: { query: search_query }
          response_body = JSON.parse(response.body)
          irrelevant_models.each do |model|
            expect(response_body).not_to include(pattern_search_api_channel(model))
          end
        end

        context 'when given search_by param set to "title"' do
          let(:title_search_query) { 'avada kedavra' }
          let(:channel_match_in_title_only) do
            create(:listed_channel, title: "Channel match in title only #{title_search_query}")
          end
          let(:channel_match_description_only) do
            create(:listed_channel, description: "Channel match in description only #{title_search_query}")
          end

          it 'returns channel with match in title' do
            channel_match_in_title_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).to include(pattern_search_api_channel(channel_match_in_title_only))
          end

          it 'does not return channel with match not in title' do
            channel_match_description_only.update_pg_search_document
            get :index, format: :json, params: { query: title_search_query, limit: 100, search_by: 'title' }
            response_body = JSON.parse(response.body)
            expect(response_body).not_to include(pattern_search_api_channel(channel_match_description_only))
          end
        end
      end

      context 'when given created_after and created_before params' do
        it 'returns models from datetime interval' do
          models_inside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_inside_interval.each do |model|
            expect(response_body).to include(pattern_search_api_channel(model))
          end
        end

        it 'does not return models that are not in datetime interval' do
          models_outside_interval.each(&:update_pg_search_document)
          get :index, format: :json, params: { created_after: '02-01-2019', created_before: '30-12-2019' }
          response_body = JSON.parse(response.body)
          models_outside_interval.each do |model|
            expect(response_body).not_to include(pattern_search_api_channel(model))
          end
        end
      end
    end
  end
end
