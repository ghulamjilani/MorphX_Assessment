# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Blog::LinkPreviewsController do
  let(:link_preview) { create(:link_preview_new) }
  let(:url) { "https://#{Forgery(:internet).domain_name}" }
  let(:current_user) { create(:blog_post_published).user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET show:' do
      context 'when returns link preview' do
        it 'does not fail and returns valid json' do
          get :show, params: { id: link_preview.id }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include link_preview.id.to_s
        end
      end
    end

    describe 'POST create:' do
      context 'when creates link preview' do
        it 'does not fail and returns valid json' do
          post :create, params: { url: url }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include url
        end
      end
    end

    describe 'GET parse:' do
      context 'when force parse link preview' do
        it 'does not fail and returns valid json' do
          get :parse, params: { id: link_preview.id }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include link_preview.url
        end
      end
    end
  end
end
