# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Blog::ImagesController do
  let(:blog_image_attached) { create(:blog_image_attached) }
  let(:blog_post) { blog_image_attached.blog_post }
  let(:blog_image) { create(:blog_image, organization: blog_post.organization) }
  let(:current_user) { blog_post.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when returns blog post images' do
        it 'does not fail and returns valid json' do
          get :index, params: { post_id: blog_post.id }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include blog_image_attached.large_url
        end
      end
    end

    describe 'GET show:' do
      context 'when returns link preview' do
        it 'does not fail and returns valid json' do
          get :show, params: { id: blog_image.id }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include blog_image.large_url
        end
      end
    end

    describe 'POST create:' do
      context 'when uploads image' do
        let(:valid_params) do
          {
            organization_id: blog_post.organization.id,
            image: fixture_file_upload(ImageSample.for_size('1x1'))
          }
        end

        it 'does not fail and returns valid json' do
          post :create, params: valid_params, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'PUT update:' do
      context 'when updates image' do
        let(:valid_params) { { id: blog_image.id, blog_post_id: blog_post.id } }

        it 'does not fail and returns valid json' do
          put :update, params: valid_params, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(response.body).to include blog_post.id.to_s
        end
      end
    end
  end
end
