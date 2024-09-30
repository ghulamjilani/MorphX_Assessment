# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V1::Public::DocumentsController do
  let(:parsed_response) { JSON.parse(response.body) }

  render_views

  describe 'GET #index' do
    before do
      @channel = FactoryBot.create(:channel)

      FactoryBot.create_list(:document, 2, channel: @channel) # visible_single_channel_docs
      FactoryBot.create_list(:document, 3) # visible_other_channels_docs
      FactoryBot.create_list(:document, 4, hidden: true) # hidden_docs
    end

    context 'when no params' do
      before { get :index, format: :json }

      it 'returns valid response' do
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        expect(parsed_response['time_now']).to be_a(String)
        expect(parsed_response['errors']).to be_a(Hash)
        expect(parsed_response['response']).to be_a(Array)
        expect(parsed_response['response'].size).to eq(5)
        # could be also tested document.json.jbuilder
        expect(parsed_response['pagination']).to be_a(Hash)
        expect(parsed_response['pagination']['count']).to eq(5)
        expect(parsed_response['pagination']['limit']).to eq(20)
        expect(parsed_response['pagination']['offset']).to eq(0)
        expect(parsed_response['pagination']['total_pages']).to eq(1)
        expect(parsed_response['pagination']['current_page']).to eq(1)
      end
    end

    context 'when limit and offset is set' do
      before { get :index, params: { limit: 3, offset: 2 }, format: :json }

      it 'returns valid response' do
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        expect(parsed_response['time_now']).to be_a(String)
        expect(parsed_response['errors']).to be_a(Hash)
        expect(parsed_response['response']).to be_a(Array)
        expect(parsed_response['response'].size).to eq(3)
        # could be also tested document.json.jbuilder
        expect(parsed_response['pagination']).to be_a(Hash)
        expect(parsed_response['pagination']['count']).to eq(5)
        expect(parsed_response['pagination']['limit']).to eq(3)
        expect(parsed_response['pagination']['offset']).to eq(2)
        expect(parsed_response['pagination']['total_pages']).to eq(2)
        expect(parsed_response['pagination']['current_page']).to eq(1)
      end
    end

    context 'when channel filter is set' do
      before { get :index, params: { channel_id: @channel.id }, format: :json }

      it 'returns valid response' do
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        expect(parsed_response['time_now']).to be_a(String)
        expect(parsed_response['errors']).to be_a(Hash)
        expect(parsed_response['response']).to be_a(Array)
        expect(parsed_response['response'].size).to eq(2)
        # could be also tested document.json.jbuilder
        expect(parsed_response['pagination']).to be_a(Hash)
        expect(parsed_response['pagination']['count']).to eq(2)
        expect(parsed_response['pagination']['limit']).to eq(20)
        expect(parsed_response['pagination']['offset']).to eq(0)
        expect(parsed_response['pagination']['total_pages']).to eq(1)
        expect(parsed_response['pagination']['current_page']).to eq(1)
      end
    end
  end

  describe 'GET #show' do
    let(:document) { FactoryBot.create(:document) }

    context 'when doc id exists and authorized access' do
      before do
        get :show, params: { id:  document.id}, format: :json
      end

      it 'returns valid response' do

        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        expect(parsed_response['time_now']).to be_a(String)
        expect(parsed_response['errors']).to be_a(Hash)
        expect(parsed_response['response']).to be_a(Hash)
        expect(parsed_response['response']['id']).to eq(document.id)
      end
    end

    context 'when document id is not exists' do
      before do
        get :show, params: { id:  100500}, format: :json
      end

      it 'returns 404 not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when document is not authorized' do
      pending 'returns 403 forbidden'
    end
  end
end
