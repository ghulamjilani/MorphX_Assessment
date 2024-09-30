# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Calendar::VideosController do
  render_views

  describe '.json request format' do
    let(:recorded_session1) { create(:recorded_session, title: 'Recorded Session 1') }
    let(:recorded_session2) do
      create(:recorded_session, title: 'Recorded Session 2', presenter: recorded_session1.presenter,
                                channel: recorded_session1.channel)
    end
    let(:recorded_session3) { create(:recorded_session, title: 'Recorded Session 3') }
    let(:recorded_session4) do
      create(:recorded_session, title: 'Recorded Session 4', presenter: recorded_session3.presenter,
                                channel: recorded_session3.channel)
    end
    let!(:video1) { recorded_session1.records.first }
    let!(:video2) { recorded_session2.records.first }
    let!(:video3) { recorded_session3.records.first }
    let!(:video4) { recorded_session4.records.first }
    let(:all_models) { [video1, video2, video3, video4] }
    let(:response_body) { JSON.parse(response.body) }

    before do
      recorded_session1.update(start_at: 10.days.from_now)
      recorded_session2.update(start_at: 20.days.from_now)
      recorded_session3.update(start_at: 12.days.from_now)
      recorded_session4.update(start_at: 22.days.from_now)
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
          expect(response_body['response']['videos']).to have(1).items
          expect(response_body['pagination']['limit']).to be(1)
        end
      end

      context 'when limit is increased' do
        it 'contains all entities' do
          all_models
          get :index, format: :json, params: { limit: 100 }
          all_models.each do |model|
            expect(response.body).to include(model.session.title)
          end
        end
      end

      context 'when given channel_id param' do
        it 'returns only relevant models' do
          all_models
          get :index, format: :json, params: { channel_id: recorded_session1.channel_id }
          expect(response.body).to include(video1.session.title)
          expect(response.body).to include(video2.session.title)
          expect(response.body).not_to include(video3.session.title)
          expect(response.body).not_to include(video4.session.title)
        end
      end

      context 'when given start_at_from param' do
        it 'returns only relevant models' do
          all_models
          get :index, format: :json, params: { start_at_from: 18.days.from_now.to_s }
          expect(response.body).not_to include(video1.session.title)
          expect(response.body).to include(video2.session.title)
          expect(response.body).not_to include(video3.session.title)
          expect(response.body).to include(video4.session.title)
        end
      end

      context 'when given start_at_to param' do
        it 'returns only relevant models' do
          all_models
          get :index, format: :json, params: { start_at_to: 18.days.from_now.to_s }
          expect(response.body).to include(video1.session.title)
          expect(response.body).not_to include(video2.session.title)
          expect(response.body).to include(video3.session.title)
          expect(response.body).not_to include(video4.session.title)
        end
      end

      context 'when given end_at_from param' do
        it 'returns only relevant models' do
          all_models
          get :index, format: :json, params: { end_at_from: 18.days.from_now.to_s }
          expect(response.body).not_to include(video1.session.title)
          expect(response.body).to include(video2.session.title)
          expect(response.body).not_to include(video3.session.title)
          expect(response.body).to include(video4.session.title)
        end
      end

      context 'when given end_at_to param' do
        it 'returns only relevant models' do
          all_models
          get :index, format: :json, params: { end_at_to: 18.days.from_now.to_s }
          expect(response.body).to include(video1.session.title)
          expect(response.body).not_to include(video2.session.title)
          expect(response.body).to include(video3.session.title)
          expect(response.body).not_to include(video4.session.title)
        end
      end
    end
  end
end
