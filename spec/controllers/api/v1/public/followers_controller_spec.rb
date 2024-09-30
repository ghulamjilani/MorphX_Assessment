# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::FollowersController do
  let!(:followable) { create(%i[user listed_channel organization].sample) }
  let!(:follower) do
    follower = create(:user)
    follower.follow(followable)
    follower
  end

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when user exsits' do
        before do
          get :index,
              params: { followable_type: followable.class.name, followable_id: followable.id, limit: 1, offset: 0, order: :desc, order_by: :created_at }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
