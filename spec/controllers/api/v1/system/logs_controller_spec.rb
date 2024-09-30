# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::System::LogsController do
  let(:user) { create(:user_with_presenter_account) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  render_views

  describe '.json request format' do
    context 'when JWT present' do
      before do
        request.headers['Authorization'] = auth_header_value
        post :create, params: { a: :b }, format: :json
      end

      it { expect(response).to be_successful }
    end
  end
end
