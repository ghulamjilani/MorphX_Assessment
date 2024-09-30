# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Im::MessagesController do
  let(:current_guest) { create(:guest) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:guest_auth_header_value) { "Bearer #{JwtAuth.guest(current_guest)}" }

  render_views

  describe '.json request format' do
    let(:im_conversation) { channel.im_conversation }
    let(:im_message) do
      im_message = create(:im_message, conversation: im_conversation)
      im_message.update(created_at: 1.hour.ago)
      im_message
    end
    let(:channel) { create(:listed_channel) }
    let(:subscription) { nil }

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET :index' do
      before do
        im_message
        subscription
        get :index, params: { conversation_id: im_conversation.id, created_at_from: (im_message.created_at - 1.hour), created_at_to: (im_message.created_at + 1.hour) }, format: :json
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given user with participate_channel_conversation credential' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include(im_message.id) }
      end

      context 'when given user with subscription' do
        let(:current_user) { create(:user) }
        let(:channel) { create(:listed_channel) }
        let(:subscription) do
          create(:stripe_db_subscription,
                 stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
                 user: current_user)
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include(channel.im_conversation.id) }
      end

      context 'when given guest user' do
        let(:auth_header_value) { guest_auth_header_value }
        let(:im_conversation) { create(:session_with_chat).im_conversation }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include(im_conversation.id) }
      end
    end

    describe 'POST :create' do
      let(:current_user) { create(:user) }
      let(:params) { { conversation_id: im_conversation.id, message: { body: Forgery(:lorem_ipsum).words(4, random: true) } } }

      context 'when creating a comment in channel conversation' do
        context 'when given random user' do
          before do
            post :create, params: params, format: :json
          end

          it { expect(response).not_to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given user with participate_channel_conversation credential' do
          let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
          let(:group) { create(:access_management_groups_credential, credential: credential).group }
          let(:groups_member) { create(:access_management_groups_member, group: group) }
          let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
          let(:channel) { groups_members_channel.channel }
          let(:current_user) { groups_members_channel.user }

          before do
            post :create, params: params, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).to include(params[:message][:body]) }
        end

        context 'when given user with subscription' do
          let(:channel) { create(:listed_channel) }
          let(:subscription) do
            create(:stripe_db_subscription,
                   stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
                   user: current_user)
          end

          before do
            subscription
            post :create, params: params, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).to include(channel.im_conversation.id) }
        end
      end

      context 'when creating a comment in session conversation' do
        let(:im_conversation) { create(:session_with_chat).im_conversation }

        context 'when given user' do
          before do
            post :create, params: params, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).to include(im_conversation.id) }
        end

        context 'when given guest' do
          let(:auth_header_value) { guest_auth_header_value }

          before do
            post :create, params: params, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

          it { expect(response.body).to include(im_conversation.id) }
        end
      end
    end

    describe 'PUT :update' do
      let(:params) do
        {
          id: im_message.id,
          conversation_id: im_conversation.id,
          message: {
            body: Forgery(:lorem_ipsum).words(4, random: true)
          }
        }
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        before do
          put :update, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given user with participate_channel_conversation credential' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }

        before do
          put :update, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given user with subscription' do
        let(:current_user) { create(:user) }
        let(:channel) { create(:listed_channel) }
        let(:subscription) do
          create(:stripe_db_subscription,
                 stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
                 user: current_user)
        end

        before do
          subscription
          put :update, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given message owner with participate_channel_conversation credential' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }
        let(:im_conversation_participant) { create(:im_conversation_participant, conversation: im_conversation, abstract_user: current_user) }
        let(:im_message) { create(:im_message, conversation: im_conversation, conversation_participant: im_conversation_participant) }

        before do
          put :update, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(assigns(:message).body).to eq(params[:message][:body]) }

        it { expect(assigns(:message).deleted_at).to be_nil }
      end

      context 'when given user with moderate_channel_conversation credential' do
        let(:group) { create(:access_management_groups_credential, credential: create(:access_management_credential, code: :moderate_channel_conversation)).group }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: create(:access_management_groups_member, group: group)) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }
        let(:im_conversation_participant) { create(:im_conversation_participant, conversation: im_conversation, abstract_user: current_user) }

        before do
          put :update, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given guest' do
        let(:auth_header_value) { guest_auth_header_value }
        let(:current_guest) { im_message.abstract_user }
        let(:im_conversation) { im_message.conversation }
        let(:im_message) { create(:im_guest_message) }

        before do
          put :update, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(response.body).to include(im_conversation.id) }
      end
    end

    describe 'DELETE :destroy' do
      let(:params) do
        {
          id: im_message.id,
          conversation_id: im_conversation.id
        }
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        before do
          delete :destroy, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given user with participate_channel_conversation credential' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }

        before do
          delete :destroy, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given user with subscription' do
        let(:current_user) { create(:user) }
        let(:channel) { create(:listed_channel) }
        let(:subscription) do
          create(:stripe_db_subscription,
                 stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
                 user: current_user)
        end

        before do
          subscription
          delete :destroy, params: params, format: :json
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(assigns(:message).deleted_at).to be_nil }
      end

      context 'when given message owner with participate_channel_conversation credential' do
        let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
        let(:group) { create(:access_management_groups_credential, credential: credential).group }
        let(:groups_member) { create(:access_management_groups_member, group: group) }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }
        let(:im_conversation_participant) { create(:im_conversation_participant, conversation: im_conversation, abstract_user: current_user) }
        let(:im_message) { create(:im_message, conversation: im_conversation, conversation_participant: im_conversation_participant) }

        before do
          delete :destroy, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(assigns(:message).deleted_at).not_to be_nil }
      end

      context 'when given user with moderate_channel_conversation credential' do
        let(:group) { create(:access_management_groups_credential, credential: create(:access_management_credential, code: :moderate_channel_conversation)).group }
        let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: create(:access_management_groups_member, group: group)) }
        let(:channel) { groups_members_channel.channel }
        let(:current_user) { groups_members_channel.user }
        let(:im_conversation_participant) { create(:im_conversation_participant, conversation: im_conversation, abstract_user: current_user) }

        before do
          delete :destroy, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(assigns(:message).deleted_at).not_to be_nil }
      end

      context 'when given guest' do
        let(:auth_header_value) { guest_auth_header_value }
        let(:current_guest) { im_message.abstract_user }
        let(:im_conversation) { im_message.conversation }
        let(:im_message) { create(:im_guest_message) }

        before do
          delete :destroy, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(assigns(:message).deleted_at).not_to be_nil }
      end
    end
  end
end
