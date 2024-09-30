# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Webrtcservice::Chat::AccessTokensController do
  describe '.json request format' do
    describe 'POST create:' do
      context 'when JWT present' do
        let(:current_user) { create(:user) }
        let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given user_type param set to User and identity set to user id' do
          it 'does not fail and returns valid json' do
            post :create, params: { user_type: 'User', identity: current_user.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end

      context 'when given user_type param set to ChatMember and identity set to user id' do
        let(:webrtcservice_chat_member) { create(:webrtcservice_chat_member) }

        it 'does not fail and returns valid json' do
          post :create, params: { user_type: 'ChatMember', identity: webrtcservice_chat_member.id }, format: :json

          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
