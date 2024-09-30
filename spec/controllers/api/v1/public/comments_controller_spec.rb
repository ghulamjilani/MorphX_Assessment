# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::CommentsController do
  let(:commentable) { comment.commentable }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        get :index, params: { commentable_type: commentable.class.to_s, commentable_id: commentable.id }, format: :json
      end

      context 'when given session as commentable' do
        let(:comment) { create(:comment) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given published recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording_published)) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given not published recording as commentable' do
        let(:comment) { create(:comment, commentable: create(:recording)) }

        it { expect(response).not_to be_successful }
      end
    end
  end
end
