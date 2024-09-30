# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Search::Blog::PostsController do
  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when given all params' do
        let(:blog_post) { create(:blog_post_published) }
        let(:params) do
          {
            query: blog_post.title,
            promo_weight: 1,
            channel_id: blog_post.channel_id,
            order_by: 'rank',
            order: 'desc',
            limit: 1
          }
        end

        before do
          get :index, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
