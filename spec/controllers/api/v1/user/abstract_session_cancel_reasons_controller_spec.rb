# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AbstractSessionCancelReasonsController do
  let(:current_user) { create(:user) }
  let(:abstract_session_cancel_reason) { create(:abstract_session_cancel_reason) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        abstract_session_cancel_reason
        request.headers['Authorization'] = auth_header_value
        get :index, params: { limit: 10, offset: 0 }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(response.body).to include abstract_session_cancel_reason.name }
    end
  end
end
