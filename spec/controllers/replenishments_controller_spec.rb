# frozen_string_literal: true

require 'spec_helper'

describe ReplenishmentsController do
  before { sign_in current_user, scope: :user }

  let(:current_user) { create(:user_with_credit_card).tap(&:create_participant!) }

  describe 'GET :new' do
    it 'works' do
      # fails with:
      # expected a gzipped response # in `generate_client_token'
      # use better stubbing?
      skip 'skip temporary'
      get :new, params: { amount: 12.99 }
      expect(response).to be_successful
    end
  end
end
