# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::CommentsController do
  let(:commentable) { comment.commentable }

  render_views

  describe '.json request format' do
    let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      let(:current_user) { create(:user) }

      before do
        get :index, params: { commentable_type: commentable.class.to_s, commentable_id: commentable.id }, format: :json
      end

      context 'when given session as commentable' do
        let(:comment) { create(:comment) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording_published)) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { commentable_type: commentable.class.to_s, commentable_id: commentable.id, id: comment.id },
                   format: :json
      end

      context 'when given comment author and session as commentable' do
        let(:comment) { create(:comment) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given comment author and recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording_published)) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      let(:params) do
        {
          commentable_type: commentable.class.to_s,
          commentable_id: commentable.id,
          body: Forgery(:lorem_ipsum).words(10, random: true)
        }
      end

      before { post :create, params: { comment: params }, format: :json }

      context 'when given session as commentable' do
        let(:current_user) { create(:user) }
        let(:commentable) { create(:immersive_session) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given recording as commentable' do
        let(:current_user) { create(:user) }
        let(:commentable) { create(:recording_published) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'PUT update:' do
      let(:params) do
        {
          commentable_type: commentable.class.to_s,
          commentable_id: commentable.id,
          body: Forgery(:lorem_ipsum).words(10, random: true)
        }
      end

      before { put :update, params: { id: comment.id, comment: params }, format: :json }

      context 'when given comment author and session as commentable' do
        let(:comment) { create(:comment) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given comment author and recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording_published)) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given commentable owner' do
        let(:params) { { id: comment.id, visible: false } }
        let(:comment) { create(:comment) }
        let(:current_user) { comment.commentable.organizer }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(comment.reload.visible).to be_falsey }
      end
    end

    describe 'DELETE destroy:' do
      let(:params) do
        {
          id: comment.id,
          commentable_type: commentable.class.to_s,
          commentable_id: commentable.id
        }
      end

      before { delete :destroy, params: params, format: :json }

      context 'when given comment author and session as commentable' do
        let(:comment) { create(:comment) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given comment author and recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording_published)) }
        let(:current_user) { comment.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
