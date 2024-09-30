# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Blog::PostsController do
  let(:current_user) { blog_post.user }
  let(:blog_post) { create(:blog_post_published) }
  let(:link_preview) { create(:link_preview_new) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        render_views

        it 'does not fail and returns valid json' do
          blog_post
          get :index, params: {}, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given limit param' do
        it 'does not fail and returns valid json' do
          get :index, params: { limit: 1 }, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given scope param set to edit' do
        it 'does not fail' do
          get :index, params: { scope: 'edit' }, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given status, limit and offset params' do
        let(:params) do
          {
            status: Blog::Post::Statuses::PUBLISHED,
            limit: 1,
            offset: 1
          }
        end

        it 'does not fail and returns valid json' do
          get :index, params: params, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given resource_type and resource_id' do
        let(:params) do
          {
            resource_type: resource.class.name.to_s,
            resource_id: resource.id
          }
        end

        render_views

        before do
          get :index, params: params, format: :json
        end

        context 'when given resource set to user' do
          let(:resource) { blog_post.user }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given resource set to channel' do
          let(:resource) { blog_post.channel }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given resource set to organization' do
          let(:resource) { blog_post.organization }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end

      context 'when given resource_type and resource_slug' do
        render_views

        let(:params) do
          {
            resource_type: resource.class.name.to_s,
            resource_slug: resource.slug
          }
        end

        before do
          get :index, params: params, format: :json
        end

        context 'when given resource set to user' do
          let(:resource) { blog_post.user }

          it 'does not fail and returns valid json' do
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given resource set to channel' do
          let(:resource) { blog_post.channel }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given resource set to organization' do
          let(:resource) { blog_post.organization }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end
    end

    describe 'GET show:' do
      render_views

      context 'when given no slug param' do
        it 'does not fail and returns valid json' do
          get :show, params: { id: blog_post.id }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given slug param' do
        it 'does not fail and returns valid json' do
          get :show, params: { id: blog_post.slug, slug: '1' }, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'POST create:' do
      let(:valid_params) do
        {
          post: {
            channel_id: blog_post.channel_id,
            title: 'Best post ever',
            body: 'lorem ipsum dolor sit amet',
            link_preview_id: link_preview.id,
            cover_attributes: {
              image: fixture_file_upload(ImageSample.for_size('300x300'))
            }
          }
        }
      end

      context 'when given no body param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:post][:body] = '' }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when given no title param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:post][:title] = '' }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when given no channel_id param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:post].delete(:title) }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when given valid params' do
        render_views

        it 'does not fail and returns valid json' do
          post :create, params: valid_params, format: :json
          expect(response).to be_successful
          expect(response.body).to include valid_params[:post][:title]
        end
      end
    end

    describe 'PUT update:' do
      let(:valid_params) do
        {
          id: blog_post.id,
          post: {
            channel_id: blog_post.channel_id,
            title: 'Best post ever',
            body: 'lorem ipsum dolor sit amet',
            status: %w[draft published hidden].sample,
            link_preview_id: link_preview.id,
            hide_author: true,
            published_at: Time.now,
            cover_attributes: {
              image: fixture_file_upload(ImageSample.for_size('300x300'))
            }
          }
        }
      end

      context 'when given valid params' do
        render_views

        it 'does not fail and returns valid json' do
          put :update, params: valid_params, format: :json
          expect(response).to be_successful
          expect(response.body).to include valid_params[:post][:title]
        end
      end
    end

    describe 'DELETE destroy:' do
      context 'when any post' do
        let(:blog_post) { create(:blog_post, status: ::Blog::Post::Statuses::ALL.sample) }

        it 'does not fail and returns valid json' do
          delete :destroy, params: { id: blog_post.id }, format: :json
          expect(response).to be_successful
        end
      end
    end

    describe 'POST vote:' do
      it 'does not fail and returns valid json' do
        post :vote, params: { id: blog_post.id }, format: :json
        expect(response).to be_successful
      end
    end
  end
end
