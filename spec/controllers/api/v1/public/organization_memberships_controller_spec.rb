# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::OrganizationMembershipsController do
  let(:organization_membership) { create(:organization_membership) }
  let(:organization_membership2) do
    create(:organization_membership, organization: organization_membership.organization)
  end
  let(:organization_membership3) do
    create(:organization_membership, organization: organization_membership.organization)
  end
  let(:organization_membership4) { create(:organization_membership) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when no params present' do
        it 'does not fail and returns valid json' do
          organization_membership
          organization_membership2
          organization_membership3
          organization_membership4
          get :index, format: :json

          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
          expect(JSON.parse(response.body)['pagination']['count']).to eq 4
        end
      end

      context 'when organization_id param is set' do
        it 'does not fail and returns valid json' do
          organization_membership
          organization_membership2
          organization_membership3
          organization_membership4
          get :index, params: { organization_id: organization_membership.organization_id }, format: :json

          expect(response).to be_successful
          expect(response.body).to include "\"id\":#{organization_membership.id},"
          expect(response.body).to include "\"id\":#{organization_membership2.id},"
          expect(response.body).to include "\"id\":#{organization_membership3.id},"
          expect(response.body).not_to include "\"id\":#{organization_membership4.id},"
        end
      end

      context 'when limit param is set' do
        it 'does not fail and returns valid json' do
          organization_membership
          organization_membership2
          organization_membership3
          organization_membership4
          get :index, params: { limit: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['response']['organization_memberships'].size).to eq(1)
          expect(JSON.parse(response.body)['pagination']['limit']).to eq 1
          expect(JSON.parse(response.body)['pagination']['total_pages']).to eq 4
        end
      end

      context 'when offset param is set' do
        it 'does not fail and returns valid json' do
          organization_membership
          organization_membership2
          organization_membership3
          organization_membership4
          get :index, params: { limit: 1, offset: 1 }, format: :json

          expect(response).to be_successful
          expect(JSON.parse(response.body)['pagination']['current_page']).to eq 2
        end
      end
    end
  end
end
