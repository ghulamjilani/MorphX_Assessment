# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::FeatureHistoryUsagesController do
  let(:feature_history_usage) { create(:feature_history_usage) }
  let(:feature_usage) { feature_history_usage.feature_usage }
  let(:current_user) { feature_usage.organization.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      let(:params) do
        {
          feature_usage_id: feature_history_usage.feature_usage_id,
          model_id: feature_history_usage.model.id,
          model_type: feature_history_usage.model.class.to_s,
          limit: 1,
          offset: 0
        }
      end

      before do
        request.headers['Authorization'] = auth_header_value
        get :index, params: params, format: :json
      end

      context 'when given organization owner' do
        it { expect(response).to be_successful }

        it { expect(response.body).to include(feature_history_usage.id) }
      end

      context 'when given user with proper credential' do
        let(:current_user) do
          current_user = create(:user)
          ::AccessManagement::CredentialsHelper.group_member_with_credential(user: current_user, code: :view_billing_report, organization: feature_usage.organization)
          current_user.update_columns(current_organization_id: feature_usage.organization_id)
          current_user
        end

        it { expect(response).to be_successful }

        it { expect(response.body).to include(feature_history_usage.id) }
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
