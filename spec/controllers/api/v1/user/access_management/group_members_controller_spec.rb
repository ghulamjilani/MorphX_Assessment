# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AccessManagement::GroupMembersController do
  let(:current_user) { create(:user) }
  let(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'PUT update:' do
      context 'when given no params' do
        let(:channel) { create(:listed_channel, organization: organization) }
        let(:member) { create(:organization_membership, organization: organization) }
        let(:groups_member) { create(:access_management_groups_member, organization_membership: member) }

        render_views

        it 'does not fail and returns valid json' do
          put :update, params: { organization_id: organization.id, id: groups_member.id, channel_ids: [channel.id] },
                       format: :json
          expect(response).to be_successful
          expect(response.body).to include channel.title
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
