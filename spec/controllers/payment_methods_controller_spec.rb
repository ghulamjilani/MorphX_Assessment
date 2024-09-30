# frozen_string_literal: true

require 'spec_helper'

describe PaymentMethodsController do
  before do
    sign_in current_user, scope: :user
  end

  let(:current_user) { create(:stripe_user) }

  describe 'PUT :update' do
    before do
      source = Stripe::Customer.create_source(current_user.stripe_customer_id,
                                              { source: @stripe_test_helper.generate_card_token })
      put :update, params: { id: source.id, primary: 1 }
    end

    it { expect(response).to be_redirect }
    it { expect(flash[:error]).not_to be_present }
  end

  describe 'POST :create' do
    before do
      post :create, params: { stripe_token: @stripe_test_helper.generate_card_token, primary: 1 }
    end

    it { expect(response).to be_redirect }
    it { expect(flash[:success]).to be_present }
    it { expect(flash[:error]).not_to be_present }
  end

  describe 'DELETE :destroy' do
    before do
      source = Stripe::Customer.create_source(current_user.stripe_customer_id,
                                              { source: @stripe_test_helper.generate_card_token })
      delete :destroy, params: { id: source.id }
    end

    it { expect(response).to be_redirect }
    it { expect(flash[:success]).to be_present }
    it { expect(flash[:error]).not_to be_present }
  end
end
