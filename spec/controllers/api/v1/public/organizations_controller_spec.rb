# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::OrganizationsController do
  let(:organization) { create(:organization, show_on_home: true) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        organization
        get :index, params: { show_on_home: true, limit: 1, order_by: 'created_at', order: 'asc', promo_weigh: '1' }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(response.body).to include(organization.name) }
    end

    describe 'GET show:' do
      it 'is successful and contains valid json' do
        get :show, format: :json, params: { id: organization.id }
        expect(response).to be_successful
        expect do
          JSON.parse(response.body)
        end.not_to raise_error, response.body
      end
    end

    describe 'GET default_location:' do
      context 'when user is not logged in' do
        before { get :default_location, format: :json, params: { id: organization.id } }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when user is logged in' do
        let(:current_user) { create(:user) }

        before do
          sign_in current_user, scope: :user
          get :default_location, format: :json, params: { id: organization.id }
        end

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
