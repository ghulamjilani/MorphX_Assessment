# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::FollowsController do
  let(:current_user) { create(:user) }
  let(:followable) { create(%i[user listed_channel organization].sample) }
  let(:not_followed) { create(%i[user listed_channel organization].sample) }
  let(:follow) { current_user.follow(followable) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      before do
        follow
      end

      context 'when given no params' do
        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include follow.id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given limit param' do
        let(:response_body) { JSON.parse(response.body) }

        before do
          get :index, params: { limit: 1 }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given limit and offset params' do
        let(:response_body) { JSON.parse(response.body) }

        before do
          get :index, params: { limit: 1, offset: 1 }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given followable_type param' do
        let(:response_body) { JSON.parse(response.body) }

        before do
          get :index, params: { followable_type: follow.followable_type }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when given id param' do
        before do
          get :show, params: { id: follow.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include follow.followable_id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given followable_type and followable_id params' do
        before do
          get :show,
              params: { followable_type: follow.followable.class.name.downcase, followable_id: follow.followable.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(response.body).to include follow.id.to_s }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      let(:not_followed) { create(%i[user listed_channel organization].sample) }

      it 'creates new follow' do
        post :create, params: { followable_type: not_followed.class.name.downcase, followable_id: not_followed.id },
                      format: :json
        expect(response).to be_successful
        expect(not_followed.followed_by?(current_user)).to eq(true)
      end
    end

    describe 'DELETE destroy:' do
      context 'when given id param' do
        let(:followable) { create(%i[user listed_channel organization].sample) }
        let(:follow) { current_user.follow(followable) }

        it 'destroys follow' do
          delete :destroy, params: { id: follow.id }, format: :json
          expect(response).to be_successful
        end
      end

      context 'when given followable_type and followable_id params' do
        let(:followable) { create(%i[user listed_channel organization].sample) }
        let(:follow) { current_user.follow(followable) }

        it 'destroys follow' do
          delete :destroy,
                 params: { followable_type: follow.followable.class.name.downcase, followable_id: follow.followable.id }, format: :json
          expect(response).to be_successful
        end
      end
    end
  end
end
