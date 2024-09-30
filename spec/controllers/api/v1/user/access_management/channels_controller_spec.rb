# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AccessManagement::ChannelsController do
  let(:current_user) { create(:user) }
  let(:organization) { create(:organization, user: current_user) }
  let!(:channel) { create(:listed_channel, organization: organization) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }

  describe '.json request format' do
    render_views

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when given no params' do
        before do
          current_user.update(current_organization_id: organization.id)
          get :index, params: {}, format: :json
        end

        context 'when given organization owner' do
          let(:organization) { create(:organization, user: current_user) }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(response.body).to include channel.title
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end

      context 'when given permission_code param' do
        before do
          current_user.update(current_organization_id: organization.id)
          get :index, params: { permission_code: credential.code }, format: :json
        end

        context 'when given organization owner' do
          let(:organization) { create(:organization, user: current_user) }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(response.body).to include channel.title
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given organization participant' do
          let(:group) { create(:access_management_groups_credential, credential: credential).group }
          let(:groups_member) { create(:access_management_groups_member, group: group) }
          let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
          let(:channel) { groups_members_channel.channel }
          let(:organization_membership) { groups_member.organization_membership }
          let(:organization) { organization_membership.organization }
          let(:current_user) { organization_membership.user }

          it { expect(response).to be_successful }

          it { expect(response.body).to include channel.title }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given organization guest' do
          let(:organization_membership) { create(:organization_membership_guest) }
          let(:organization) { organization_membership.organization }
          let(:current_user) { organization_membership.user }

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end
  end
end
