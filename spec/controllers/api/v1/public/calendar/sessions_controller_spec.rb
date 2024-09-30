# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Calendar::SessionsController do
  render_views

  describe '.json request format' do
    let!(:livestream_session1) do
      create(:session_with_livestream_only_delivery, title: 'Livestream Session 1', start_at: 20.days.from_now)
    end
    let!(:livestream_session2) do
      create(:session_with_livestream_only_delivery, title: 'Livestream Session 2', start_at: 10.days.from_now)
    end
    let!(:recorded_session1) do
      create(:recorded_session, title: 'Recorded Session 1', presenter: livestream_session1.presenter,
                                channel: livestream_session1.channel)
    end
    let!(:recorded_session2) do
      create(:recorded_session, title: 'Recorded Session 2', presenter: livestream_session2.presenter,
                                channel: livestream_session2.channel)
    end
    let(:all_models) { [livestream_session1, livestream_session2, recorded_session1, recorded_session2] }
    let(:response_body) { JSON.parse(response.body) }

    before do
      recorded_session1.update(start_at: 10.days.from_now)
      recorded_session2.update(start_at: 22.days.from_now)
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
          get :index, format: :json, params: { limit: 1 }
          response_body = JSON.parse(response.body)
          expect(response_body['response']['sessions']).to have(1).items
          expect(response_body['pagination']['limit']).to be(1)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models
          get :index, format: :json, params: { limit: 100 }
          all_models.each do |model|
            expect(response.body).to include(model.title)
          end
        end
      end

      context 'when given channel_id param' do
        it 'returns only relevant models' do
          get :index, format: :json, params: { channel_id: livestream_session1.channel_id }
          expect(response.body).to include(livestream_session1.title)
          expect(response.body).to include(recorded_session1.title)
          expect(response.body).not_to include(livestream_session2.title)
          expect(response.body).not_to include(recorded_session2.title)
        end
      end

      context 'when given start_at_from param' do
        it 'returns only relevant models' do
          get :index, format: :json, params: { start_at_from: 18.days.from_now.to_s }
          expect(response.body).to include(livestream_session1.title)
          expect(response.body).not_to include(livestream_session2.title)
          expect(response.body).not_to include(recorded_session1.title)
          expect(response.body).to include(recorded_session2.title)
        end
      end

      context 'when given start_at_to param' do
        it 'returns only relevant models' do
          get :index, format: :json, params: { start_at_to: 18.days.from_now.to_s }
          expect(response.body).not_to include(livestream_session1.title)
          expect(response.body).to include(livestream_session2.title)
          expect(response.body).to include(recorded_session1.title)
          expect(response.body).not_to include(recorded_session2.title)
        end
      end

      context 'when given end_at_from param' do
        it 'returns only relevant models' do
          get :index, format: :json, params: { end_at_from: 18.days.from_now.to_s }
          expect(response.body).to include(livestream_session1.title)
          expect(response.body).not_to include(livestream_session2.title)
          expect(response.body).not_to include(recorded_session1.title)
          expect(response.body).to include(recorded_session2.title)
        end
      end

      context 'when given end_at_to param' do
        it 'returns only relevant models' do
          get :index, format: :json, params: { end_at_to: 18.days.from_now.to_s }
          expect(response.body).not_to include(livestream_session1.title)
          expect(response.body).to include(livestream_session2.title)
          expect(response.body).to include(recorded_session1.title)
          expect(response.body).not_to include(recorded_session2.title)
        end
      end
    end
  end
end
