# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::GuestsController do
  describe '.json request format' do
    render_views

    describe 'POST create' do
      let(:params) do
        {
          public_display_name: Forgery(:name).full_name,
          visitor_id: SecureRandom.uuid
        }
      end

      before do
        post :create, params: params, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(assigns(:current_guest)).not_to be_blank }

      it { expect(assigns(:guest_jwt)).not_to be_blank }

      it { expect(assigns(:refresh_jwt)).not_to be_blank }
    end

    describe 'PUT update' do
      let(:current_guest) { create(:guest) }

      before do
        request.headers['Authorization'] = "Bearer #{JwtAuth.refresh_guest(current_guest)}"
        put :update, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(assigns(:current_guest)).not_to be_blank }

      it { expect(assigns(:guest_jwt)).not_to be_blank }

      it { expect(assigns(:refresh_jwt)).not_to be_blank }
    end
  end
end
