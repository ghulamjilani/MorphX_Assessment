# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::OrganizationMembershipsController do
  let(:organization_membership) { create(:organization_membership) }
  let(:current_user) { organization_membership.user }
  let(:organization) { organization_membership.organization }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    render_views

    describe 'GET index:' do
      before do
        get :index, params: { organization_id: organization.id }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: organization_membership.id }, format: :json
      end

      context 'when current user is organization membership user' do
        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when current user is organization owner' do
        let(:current_user) { organization.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'PUT update:' do
      context 'when current user is organization membership user' do
        context 'when updating status from pending to active' do
          let(:organization_membership) { create(:organization_membership_pending) }

          before do
            put :update, params: { id: organization_membership.id, status: ::OrganizationMembership::Statuses::ACTIVE }, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when updating status from active to cancelled' do
          before do
            put :update, params: { id: organization_membership.id, status: ::OrganizationMembership::Statuses::CANCELLED }, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when updating status from active to suspended' do
          before do
            put :update, params: { id: organization_membership.id, status: ::OrganizationMembership::Statuses::SUSPENDED }, format: :json
          end

          it { expect(response).not_to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end

      context 'when current user is organization member with credentials' do
        context 'when updating status from active to suspended' do
          let(:groups_credential) { create(:access_management_organizational_groups_manage_admin_credential) }
          let(:groups_member) { create(:access_management_organization_groups_member, group: groups_credential.group) }
          let(:organization_membership) { groups_member.organization_membership }
          let(:editable_organization_membership) { create(:organization_membership, organization: organization_membership.organization) }

          before do
            put :update, params: { id: editable_organization_membership.id, status: ::OrganizationMembership::Statuses::SUSPENDED }, format: :json
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end

      context 'when current user is organization owner' do
        let(:current_user) { organization.user }

        before do
          put :update, params: { id: organization_membership.id, status: ::OrganizationMembership::Statuses::SUSPENDED }, format: :json
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
