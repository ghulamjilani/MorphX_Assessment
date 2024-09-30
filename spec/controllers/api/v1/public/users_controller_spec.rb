# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::UsersController do
  let(:user) { create(:user_with_presenter_account) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when user exsits' do
        before { get :show, params: { id: user.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET fetch_avatar:' do
      before { get :fetch_avatar, params: { email: user.email }, format: :json }

      it { expect(response).to be_successful }
      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end

    describe 'GET creator_info:' do
      before { get :creator_info, params: { id: user.id }, format: :json }

      it { expect(response).to be_successful }
      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end
  end
end
