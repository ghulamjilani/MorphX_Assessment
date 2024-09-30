# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::FeatureUsagesController do
  let(:feature_usage) { create(:feature_usage) }
  let(:current_user) { feature_usage.organization.user }
  let(:auth_header_value) { JwtAuth.user(current_user) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        request.headers['Authorization'] = auth_header_value
        get :index, params: { code: feature_usage.plan_feature.code, limit: 1, offset: 0 }, format: :json
      end

      context 'when given organization owner' do
        it { expect(response).to be_successful }

        it { expect(response.body).to include(feature_usage.id) }
      end

      context 'when given user with proper credential' do
        let(:current_user) do
          current_user = create(:user)
          ::AccessManagement::CredentialsHelper.group_member_with_credential(user: current_user, code: :view_billing_report, organization: feature_usage.organization)
          current_user.update_columns(current_organization_id: feature_usage.organization_id)
          current_user
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include(feature_usage.id) }
      end

      context 'when given organization member without proper credential' do
        let(:current_user) do
          current_user = create(:organization_membership, organization: feature_usage.organization).user
          current_user.update_columns(current_organization_id: feature_usage.organization_id)
          current_user.reload
        end

        it { expect(response).not_to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error }
      end
    end
  end
end
