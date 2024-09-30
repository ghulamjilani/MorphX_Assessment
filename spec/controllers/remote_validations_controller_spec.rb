# frozen_string_literal: true

require 'spec_helper'

describe RemoteValidationsController do
  before { sign_in current_user, scope: :user }

  let(:current_user) { create(:user) }

  describe 'POST :user_slug' do
    render_views

    context 'when given unique unoccupied slug name' do
      it 'does not fail' do
        post :user_slug, params: { slug: 'abcd' }, format: :js

        expect(response).to be_successful
        expect(flash.now[:error]).to be_blank
      end
    end

    context "given current_user's slug name" do
      it 'does not fail' do
        post :user_slug, params: { slug: current_user.slug }, format: :js

        expect(response).to be_successful
        expect(flash.now[:error]).to be_blank
      end
    end
  end
end
