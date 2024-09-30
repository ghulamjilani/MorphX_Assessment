# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Organization::OrganizationMembershipsController do
  let(:om) { create(:organization_membership) }
  let(:om1) { create(:organization_membership) }
  let(:om2) { create(:organization_membership, organization: om1.organization) }
  let(:om3) { create(:organization_membership, organization: om1.organization) }
  let(:current_organization) { om1.organization }
  let(:auth_header_value) { "Bearer #{JwtAuth.organization(om1.organization)}" }
  let(:response_body) { JSON.parse(response.body) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, params: { organization_id: current_organization.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no organization_id param' do
          context 'with no params' do
            it 'does not fail and returns valid json' do
              om
              om1
              om2
              get :index, params: { organization_id: current_organization.id }, format: :json
              response_body = JSON.parse(response.body)

              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response).to be_successful
              expect(response_body).not_to include(pattern_organization_membership(om))
              expect(response_body).to include(pattern_organization_membership(om1))
              expect(response_body).to include(pattern_organization_membership(om2))
              expect(response_body['pagination']['count']).to eq(2)
            end
          end

          context 'when given limit param' do
            it 'does not fail and returns valid json' do
              om
              om1
              om2
              get :index, params: { organization_id: current_organization.id, limit: 1 }, format: :json

              expect(response).to be_successful
              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response_body['pagination']['count']).to eq(2)
              expect(response_body['pagination']['total_pages']).to eq(2)
              expect(response_body['pagination']['current_page']).to eq(1)
              expect(response_body).to include(pattern_organization_membership(om1))
              expect(response_body).not_to include(pattern_organization_membership(om2))
            end
          end

          context 'when given limit and offset params' do
            it 'does not fail and returns valid json' do
              om
              om1
              om2
              get :index, params: { organization_id: current_organization.id, limit: 1, offset: 1 }, format: :json

              expect(response).to be_successful
              expect { JSON.parse(response.body) }.not_to raise_error, response.body
              expect(response_body['pagination']['count']).to eq(2)
              expect(response_body['pagination']['total_pages']).to eq(2)
              expect(response_body['pagination']['current_page']).to eq(2)
              expect(response_body).not_to include(pattern_organization_membership(om1))
              expect(response_body).to include(pattern_organization_membership(om2))
            end
          end
        end

        context 'when given organization_id param' do
          it 'does not fail and returns valid json' do
            om
            om1
            om2
            get :index, params: { organization_id: om.organization.id }, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body).to include(pattern_organization_membership(om))
            expect(response_body).not_to include(pattern_organization_membership(om1))
            expect(response_body).not_to include(pattern_organization_membership(om2))
            expect(response_body['pagination']['count']).to eq(1)
          end
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { organization_id: om.organization.id, id: om.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when organization membership exists' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { organization_id: om.organization.id, id: om.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end
    end
  end
end
