# frozen_string_literal: true

require 'spec_helper'

describe PaymentMethodsController do
  before do
    sign_in current_user, scope: :user
  end

  describe 'PUT :update' do
    context 'when given user without stripe account' do
      let(:current_user) { create(:user) }

      it 'redirects with flash error' do
        put :update, params: { id: 'any_card', primary: '1' }
        expect(response).to be_redirect
        expect(flash[:error]).to eq('Access Denied')
      end
    end

    # Skip for now
    context 'when given user with stripe account' do
      let(:current_user) { create(:stripe_user) }

      it 'updates default card' do
        Stripe::Customer.create_source(current_user.stripe_customer_id,
                                       { source: @stripe_test_helper.generate_card_token })
        card2 = Stripe::Customer.create_source(current_user.stripe_customer_id,
                                               { source: @stripe_test_helper.generate_card_token })
        put :update, params: { id: card2.id, primary: '1' }
        expect(response).to be_redirect
        expect(current_user.stripe_customer.default_source.id).to eq(card2.id)
      end
    end
  end

  describe 'POST :create' do
    context 'when given user without stripe account' do
      let(:current_user) { create(:user) }

      it 'creates stripe user with source' do
        expect(current_user.stripe_customer_id).to be_nil
        post :create, params: { stripe_token: @stripe_test_helper.generate_card_token, primary: '1' }
        expect(response).to be_redirect
        expect(flash[:success]).to eq('Card was successfully added')
        expect(current_user.reload.stripe_customer_id).not_to be_nil
        expect(current_user.stripe_customer_sources.length).to eq(1)
      end
    end

    context 'when given user with stripe account' do
      let(:current_user) { create(:stripe_user) }

      it 'creates source' do
        expect(current_user.stripe_customer_sources.length).to eq(0)
        post :create, params: { stripe_token: @stripe_test_helper.generate_card_token, primary: '1' }
        expect(response).to be_redirect
        expect(flash[:success]).to eq('Card was successfully added')
        current_user.reload
        expect(current_user.stripe_customer_sources.length).to eq(1)
      end

      it 'validates existing card' do
        card_token = @stripe_test_helper.generate_card_token
        source = Stripe::Customer.create_source(current_user.stripe_customer_id, { source: card_token })
        post :create, params: { stripe_token: @stripe_test_helper.generate_card_token, primary: '1' }
        expect(response).to be_redirect
        expect(flash[:error]).to eq("#{source.last4} card already exists")
      end
    end
  end

  describe 'DELETE :destroy' do
    context 'when given user without stripe account' do
      let(:current_user) { create(:user) }

      it 'redirects with flash error' do
        delete :destroy, params: { id: 'any_card' }
        expect(response).to be_redirect
        expect(flash[:error]).to eq('Access Denied')
      end
    end

    context 'when given user with stripe account' do
      let(:current_user) { create(:stripe_user) }

      it 'removes card' do
        Stripe::Customer.create_source(current_user.stripe_customer_id,
                                       { source: @stripe_test_helper.generate_card_token })
        expect(current_user.stripe_customer_sources.length).to eq(1)
        card = current_user.stripe_customer_sources[0]
        delete :destroy, params: { id: card.id }

        expect(response).to be_redirect
        expect(flash[:success]).to eq('Payment method has been removed')
        expect(current_user.stripe_customer_sources.length).to eq(0)
      end
    end
  end
end
