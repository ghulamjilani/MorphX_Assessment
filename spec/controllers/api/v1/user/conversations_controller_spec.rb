# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ConversationsController do
  let(:current_user) { create(:user) }
  let(:conversant_user) { create(:user) }
  let(:receipt0) { conversant_user.send_message(current_user, 'Body', 'Subject') }
  let(:receipt1) { current_user.reply_to_conversation(receipt0.conversation, 'Reply body 1') }
  let(:receipt2) { current_user.reply_to_conversation(receipt1.conversation, 'Reply body 2') }
  let(:receipt_read) do
    receipt_read = current_user.reply_to_conversation(receipt2.conversation, 'Reply body read')
    receipt_read.mark_as_read
    receipt_read
  end
  let(:receipt_unread) do
    receipt_unread = current_user.reply_to_conversation(receipt2.conversation, 'Reply body unread')
    receipt_unread.mark_as_unread
    receipt_unread
  end
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        receipt1
        receipt2
      end

      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          it 'does not fail and returns valid json' do
            get :index, params: {}, format: :json

            expect(response).to be_successful
            expect(response.body).to include receipt1.conversation.id.to_s
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end

        context 'when given box param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { box: %w[inbox sentbox trash conversations].sample }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end
    end

    describe 'GET show:' do
      it 'does not fail and returns valid json' do
        request.headers['Authorization'] = auth_header_value
        get :show, params: { id: receipt2.conversation.id }, format: :json

        expect(response).to be_successful
        expect(response.body).to include receipt2.conversation.id.to_s
        expect { JSON.parse(response.body) }.not_to raise_error, response.body
      end
    end

    describe 'POST mark_as_read:' do
      it 'marks conversation receipts as read' do
        request.headers['Authorization'] = auth_header_value
        post :mark_as_read, params: { id: receipt_unread.conversation.id }, format: :json
        expect(response).to be_successful
        receipt_unread.reload
        expect(receipt_unread.is_read).to eq(true)
      end
    end

    describe 'POST mark_as_unread:' do
      it 'marks conversation receipts as unread' do
        request.headers['Authorization'] = auth_header_value
        post :mark_as_unread, params: { id: receipt_read.conversation.id }, format: :json
        expect(response).to be_successful
        receipt_read.reload
        expect(receipt_read.is_read).to eq(false)
      end
    end

    describe 'DELETE destroy:' do
      let(:valid_params) { { id: [receipt2.conversation.id] } }

      it 'marks conversation receipts as deleted' do
        request.headers['Authorization'] = auth_header_value
        delete :destroy, params: valid_params, format: :json
        expect(response).to be_successful
        receipt1.reload
        receipt2.reload
        expect(receipt1.deleted).to be_truthy
        expect(receipt2.deleted).to be_truthy
      end
    end
  end
end
