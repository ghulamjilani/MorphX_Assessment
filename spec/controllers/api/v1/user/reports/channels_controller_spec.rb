# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Reports::ChannelsController do
  let(:current_user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    render_views

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      context 'when organization owner' do
        let(:organization) { create(:organization, user: current_user) }
        let!(:channel) { create(:channel, organization: organization) }

        before do
          current_user.update(current_organization_id: organization.id)
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include channel.title }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when has credential view_revenue_report' do
        let(:organization) { create(:organization) }
        let!(:channel) { create(:channel, organization: organization) }

        before do
          membership = create(:organization_membership, user: current_user, organization: organization)
          credential = create(:admin_credential, code: :view_revenue_report, is_master_only: true, is_for_channel: true)
          group = create(:access_management_organizational_group, organization: organization)
          create(:access_management_groups_credential, group: group, credential: credential)
          create(:access_management_groups_member, group: group, organization_membership: membership)
          current_user.update(current_organization_id: organization.id)
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include channel.title }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given platform owner user' do
        let(:organization) { create(:organization) }
        let(:channel) { create(:channel, organization: organization) }

        before do
          session = create(:session, channel: channel)
          create(:revenue_purchased_item, organization_id: organization.id, channel_id: channel.id,
                                          purchased_item_id: session.id, purchased_item_type: 'Session', type: :livestream_access)
          current_user.update(platform_role: :platform_owner)
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include channel.title }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
