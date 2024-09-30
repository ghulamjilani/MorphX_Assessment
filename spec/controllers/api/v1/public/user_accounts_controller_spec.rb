# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::UserAccountsController do
  let(:user_account) { create(:user_with_presenter_account).user_account }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when user account exsits' do
        before { get :show, params: { id: user_account.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
