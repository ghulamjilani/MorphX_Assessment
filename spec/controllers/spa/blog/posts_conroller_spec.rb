# frozen_string_literal: true

require 'spec_helper'

describe Spa::Blog::PostsController do
  render_views

  describe 'GET o/:organization_id/blog/:post_id' do
    context 'when user is a guest' do
      context 'when post is unpublished' do
        let(:blog_post) { create(%i[blog_post_draft blog_post_hidden].sample) }

        it 'redirects to root' do
          get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
          expect(response).to be_redirect
        end
      end

      context 'when post is published' do
        let(:blog_post) { create(:blog_post_published) }

        it 'shows post' do
          get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
          expect(response).to be_successful
        end
      end
    end

    context 'when user is logged in' do
      before do
        sign_in(current_user)
      end

      context 'when user is post creator' do
        let(:current_user) { blog_post.user }

        context 'when post is unpublished' do
          let(:blog_post) { create(%i[blog_post_draft blog_post_hidden].sample) }

          it 'shows post' do
            get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
            expect(response).to be_successful
          end
        end

        context 'when post is published' do
          let(:blog_post) { create(:blog_post_published) }

          it 'shows post' do
            get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
            expect(response).to be_successful
          end
        end
      end

      context 'when user is not the post creator' do
        let(:current_user) { create(:user) }

        context 'when post is unpublished' do
          let(:blog_post) { create(%i[blog_post_draft blog_post_hidden].sample) }

          it 'redirects to root' do
            get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
            expect(response).to be_redirect
          end
        end

        context 'when post is published' do
          let(:blog_post) { create(:blog_post_published) }

          it 'shows post' do
            get :show, params: { id: blog_post.slug, organization_id: blog_post.organization.slug }
            expect(response).to be_successful
          end
        end
      end
    end
  end
end
