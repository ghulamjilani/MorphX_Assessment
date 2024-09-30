# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Blog::CommentsController do
  let(:current_user) { blog_post.user }
  let(:blog_post) { create(:blog_post) }
  let(:comment) { create(:blog_comment, user: current_user) }
  let(:comment_on_comment) { create(:blog_comment_on_comment, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:link_preview) { FactoryBot.create(:link_preview) }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      before do
        blog_post
        comment
        comment_on_comment
      end

      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it 'does not fail' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given post_id param' do
        before do
          get :index, params: { post_id: comment_on_comment.blog_post_id }, format: :json
        end

        it 'does not fail' do
          expect(response).to be_successful
          expect(response.body).to include comment_on_comment.id.to_s
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given user_id param' do
        before do
          get :index, params: { user_id: comment_on_comment.user_id }, format: :json
        end

        it 'does not fail' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given commentable_id and commentable_type params' do
        before do
          get :index,
              params: { commentable_id: comment_on_comment.commentable_id, commentable_type: comment_on_comment.commentable_type }, format: :json
        end

        it 'does not fail' do
          expect(response).to be_successful
          expect(response.body).to include comment_on_comment.id.to_s
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given limit and offset params' do
        before do
          get :index, params: { limit: 1, offset: 1 }, format: :json
        end

        it 'does not fail' do
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: comment_on_comment.id }, format: :json
      end

      it 'does not fail' do
        expect(response).to be_successful
        expect(response.body).to include comment_on_comment.id.to_s
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end

    describe 'POST create:' do
      let(:commentable) { FactoryBot.create(%i[blog_post_published blog_comment blog_comment_on_comment].sample) }
      let(:valid_params) do
        {
          comment: {
            commentable_id: commentable.id,
            commentable_type: commentable.class.name.to_s,
            body: Forgery(:lorem_ipsum).words(20, random: true),
            featured_link_preview_id: link_preview.id
          }
        }
      end

      context 'when given no body param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:comment][:body] = '' }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given no commentable_id param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:comment].delete(:commentable_id) }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given no commentable_type param' do
        let(:invalid_params) do
          valid_params.tap { |p| p[:comment].delete(:commentable_type) }
          valid_params
        end

        it 'fails' do
          post :create, params: invalid_params, format: :json
          expect(response).not_to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given valid params' do
        let(:valid_params) do
          {
            comment: {
              commentable_id: commentable.id,
              commentable_type: commentable.class.name.to_s,
              body: Forgery(:lorem_ipsum).words(20, random: true)
            }
          }
        end

        it 'does not fail' do
          post :create, params: valid_params, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'PUT update:' do
      context 'when given valid params' do
        let(:valid_params) do
          {
            id: comment.id,
            comment: {
              body: 'lorem ipsum dolor sit amet',
              featured_link_preview_id: link_preview.id
            }
          }
        end

        it 'does not fail' do
          put :update, params: valid_params, format: :json
          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'DELETE destroy:' do
      let(:comment) { create(:blog_comment, user_id: current_user.id) }

      it 'does not fail' do
        delete :destroy, params: { id: comment.id }, format: :json
        expect(response).to be_successful
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end
  end
end
