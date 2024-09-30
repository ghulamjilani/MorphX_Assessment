# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Im::SessionConversationsController do
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    let(:session) { create(:session_with_chat) }
    let(:channel_image) { create(:main_channel_image, channel: session.channel) }
    let(:im_conversation) { session.im_conversation }

    describe 'GET :show' do
      context 'when given no authorization header' do
        before do
          im_conversation
          channel_image
          get :show, params: { session_id: session.id }, format: :json
        end
      end

      context 'when given authorization header' do
        before do
          request.headers['Authorization'] = auth_header_value
          im_conversation
          get :show, params: { session_id: session.id }, format: :json
        end

        context 'when given random user' do
          let(:abstract_user) { create(:user) }
          let(:auth_header_value) { "Bearer #{JwtAuth.user(abstract_user)}" }

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given random guest' do
          let(:abstract_user) { create(:guest) }
          let(:auth_header_value) { "Bearer #{JwtAuth.guest(abstract_user)}" }

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end
  end
end
