# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ReceiptsController do
  let(:current_user) { create(:user) }
  let(:conversant_user) { create(:user) }
  let(:receipt0) { conversant_user.send_message(current_user, 'Body', 'Subject') }
  let(:receipt_unread) do
    receipt_unread = current_user.reply_to_conversation(receipt0.conversation, 'Reply body unread')
    receipt_unread.mark_as_unread
    receipt_unread
  end
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      before do
        request.headers['Authorization'] = auth_header_value
        get :show, params: { id: receipt_unread.id }, format: :json
      end

      it { expect(response).to be_successful }
      it { expect(response.body).to include receipt_unread.id.to_s }
      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end

    describe 'PUT update:' do
      it 'updates receipt attributes' do
        request.headers['Authorization'] = auth_header_value
        expect(receipt_unread.is_read).to eq(false)
        put :update, params: { id: receipt_unread.id, receipt: { is_read: true } }, format: :json
        expect(response).to be_successful
        receipt_unread.reload
        expect(receipt_unread.is_read).to eq(true)
      end
    end
  end
end
