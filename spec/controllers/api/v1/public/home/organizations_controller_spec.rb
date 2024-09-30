# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Home::OrganizationsController do
  let(:organization) { create(:organization, show_on_home: true) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        organization
        get :index, params: { limit: 1, order_by: 'created_at', order: 'asc', promo_weigh: '1' }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(response.body).to include(organization.name) }
    end
  end
end
