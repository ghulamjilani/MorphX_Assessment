# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V1::User::DocumentsController do
  let(:parsed_response) { JSON.parse(response.body) }

  render_views

  context 'when un-authenticated request on' do
    it 'GET #index - returns 401 unauthenticated' do
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'GET #show - returns 401 unauthenticated' do
      get :show, params: {id: 123}, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'POST #create - returns 401 unauthenticated' do
      post :create, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'PUT #update - returns 401 unauthenticated' do
      put :update, params: {id: 123}, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'DELETE #destroy - returns 401 unauthenticated' do
      delete :destroy, params: {id: 123}, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when authenticated request on' do
    let(:channel) { FactoryBot.create(:channel) }
    let(:current_user) { channel.organization.user }
    let(:headers) { "Bearer #{JwtAuth.user(current_user)}" }
    before do
      request.headers['Authorization'] = headers
    end

    describe 'GET #index -' do
      it 'returns 200 with the list of data' do
        get :index, format: :json
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
      end
    end

    describe 'GET #show -' do
      let(:document) { FactoryBot.create(:document) }
      it 'returns 200 with the record' do
        get :show, params: {id: document.id}, format: :json
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
      end
    end

    describe 'POST #create -' do
      it 'returns 200 and creates document with attached pdf' do
        blob = FactoryBot.create(:active_storage_blob_pdf)

        post :create, params: {
          document: {
            channel_id: channel.id,
            file: blob.signed_id
          }
        }, format: :json
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        expect(Document.count).to eq(1)
        expect(Document.last.file).to be_attached
      end
    end

    describe 'PUT #update' do
      let(:document) { FactoryBot.create(:document, channel: channel) }

      it 'returns 200 and updates document' do
        put :update, params: {
          id: document.id,
          document: {
            title: 'changed'
          }
        }, format: :json
        expect(response).to have_http_status(:ok)
        expect(parsed_response['status']).to eq('OK')
        doc = Document.find(document.id)
        expect(doc.title).to eq('changed')
      end
    end

    describe 'DELETE #destroy' do
      it 'returns 204' do
        document = FactoryBot.create(:document, channel: channel)
        delete :destroy, params: {id: document.id}, format: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
