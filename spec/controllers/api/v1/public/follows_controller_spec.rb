# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::FollowsController do
  let!(:followable) { create(%i[user listed_channel organization].sample) }
  let!(:follower) do
    follower = create(:user)
    follower.follow(followable)
    follower
  end

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when given follower_id and follower_type params' do
        before { get :index, params: { follower_id: follower.id, follower_type: follower.class.name }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given follower_id, follower_type, followable_type, limit, offset, order and order_by params' do
        before do
          get :index,
              params: { follower_id: follower.id, follower_type: follower.class.name, followable_type: followable.class.name, limit: 1, offset: 0, order: :desc, order_by: :created_at }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
