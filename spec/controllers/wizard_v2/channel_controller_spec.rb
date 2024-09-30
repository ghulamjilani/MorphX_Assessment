# frozen_string_literal: true

require 'spec_helper'

describe WizardV2::ChannelController do
  render_views

  before do
    sign_in current_user, scope: :user
  end

  describe 'GET :show' do
    context 'with non creator' do
      let(:current_user) { create(:user) }

      it 'works' do
        get :show
        expect(response).to be_redirect
      end
    end

    context 'when creator with organization and without channel' do
      let(:current_user) { create(:organization).user }

      it 'works' do
        get :show
        expect(response).to be_successful
      end
    end

    context 'when creator with channel and organization' do
      let(:current_user) { create(:listed_channel).organization.user }

      it 'works' do
        get :show
        expect(response).to be_redirect
      end
    end
  end

  describe 'PUT :update' do
    let(:valid_params) do
      { channel: { title: 'Channel Title', category_id: create(:channel_category).id,
                   tag_list: 'bla,title,description' } }
    end

    context 'when summary enabled' do
      let(:current_user) { create(:organization).user }

      it 'works' do
        put :update, params: valid_params
        expect(response).to redirect_to(wizard_v2_summary_path)
      end
    end

    context 'when summary disabled' do
      let(:current_user) { create(:organization).user }

      before do
        Rails.application.credentials.global[:wizard][:summary] = false
      end

      after do
        Rails.application.credentials.global[:wizard][:summary] = true
      end

      it 'works' do
        put :update, params: valid_params
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
