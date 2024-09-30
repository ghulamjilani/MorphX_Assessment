# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::InteractiveAccessTokensController do
  let(:interactive_access_token) { create(:interactive_access_token) }

  describe '.json request format' do
    describe 'GET show:' do
      let(:params) { { id: interactive_access_token.token } }

      before do
        get :show, params: params, format: :json
      end

      context 'when current user is session presenter' do
        it { expect(response).to be_successful }
      end
    end
  end
end
