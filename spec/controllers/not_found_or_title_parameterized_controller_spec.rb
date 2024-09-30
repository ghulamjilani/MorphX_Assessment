# frozen_string_literal: true

require 'spec_helper'

describe NotFoundOrTitleParameterizedController do
  describe 'preview_share' do
    let(:interactive_access_token) { create(:interactive_access_token) }
    let(:immersive_session) { interactive_access_token.session }

    render_views

    context 'when user not logged in' do
      before do
        get :preview_share, params: { raw_slug: immersive_session.slug }, format: :js
      end

      it { expect(response).to be_successful }

      it { expect(response.body).not_to include(interactive_access_token.token) }
    end

    context 'when user logged in' do
      before do
        sign_in current_user, scope: :user
        get :preview_share, params: { raw_slug: immersive_session.slug }, format: :js
      end

      context 'when not session creator' do
        let(:current_user) { create(:user) }

        it { expect(response).to be_successful }

        it { expect(response.body).not_to include(interactive_access_token.token) }
      end

      context 'when session presenter user' do
        let(:current_user) { immersive_session.organization.user }

        it { expect(response).to be_successful }

        it { expect(response.body).to include(interactive_access_token.absolute_url) }
      end
    end
  end
end
