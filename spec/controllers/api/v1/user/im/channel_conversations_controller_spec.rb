# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Im::ChannelConversationsController do
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given random user' do
        let(:channel) { create(:listed_channel) }
        let(:current_user) { create(:user) }

        before do
          channel
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).not_to include(channel.im_conversation.id) }
      end

      context 'when given user with credentials' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }

        before do
          channel
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include(channel.im_conversation.id) }
      end

      context 'when given user with subscription' do
        let(:current_user) { create(:user) }
        let(:channel) { create(:listed_channel) }

        before do
          create(:stripe_db_subscription,
                 stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
                 user: current_user)

          get :index, params: {}, format: :json
        end

        context 'when channel is not archived' do
          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).to include(channel.im_conversation.id) }
        end

        context 'when channel is archived' do
          let(:channel) { create(:archived_channel) }

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).not_to include(channel.im_conversation.id) }
        end
      end
    end
  end
end
