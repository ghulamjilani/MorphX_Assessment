# frozen_string_literal: true

require 'spec_helper'

describe ApplicationCable::Connection, type: :channel do
  let(:abstract_user) { create(%i[user guest].sample) }
  let(:auth_token) { ::Auth::WebsocketToken.create(abstract_user:, visitor_id: SecureRandom.uuid).id }
  let(:mount_path) { "/cable?auth=#{auth_token}" }

  context 'when given no auth token' do
    let(:mount_path) { '/cable' }

    it { expect { connect mount_path }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError) }
  end

  context 'when given auth token' do
    context 'when given token without abstract user' do
      let(:auth_token) { ::Auth::WebsocketToken.create(abstract_user: nil, visitor_id: SecureRandom.uuid).id }

      it 'sets the user for connection' do
        connect mount_path
        expect(connection.current_user).to be_blank
      end
    end

    context 'when given user token' do
      let(:abstract_user) { create(:user) }

      it 'sets the user for connection' do
        connect mount_path
        expect(connection.current_user.id).to eq abstract_user.id
      end
    end

    context 'when given guest token' do
      let(:abstract_user) { create(:guest) }

      it 'sets the guest for connection' do
        connect mount_path
        expect(connection.current_guest.id).to eq abstract_user.id
      end
    end
  end
end
