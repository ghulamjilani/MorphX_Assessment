# frozen_string_literal: true

require 'spec_helper'

describe WizardV2::BusinessController do
  render_views

  before do
    sign_in current_user, scope: :user
  end

  describe 'GET :show' do
    context 'with non creator' do
      let(:current_user) { create(:user) }

      it 'works' do
        get :show
        expect(response).to be_successful
      end
    end

    context 'when creator' do
      let(:current_user) { create(:channel, status: :approved).organizer }

      it 'works' do
        get :show
        expect(response).to be_redirect
      end
    end

    context 'when no service subscription' do
      let(:current_user) { create(:user) }

      before do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = true
      end

      after do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = false
      end

      it 'redirects' do
        get :show
        expect(response).to redirect_to(spa_pricing_index_url)
      end
    end
  end

  describe 'PUT :update' do
    let(:current_user) { create(:user) }

    context 'when valid organization Cover' do
      before do
        put :update, format: :json, params: valid_params
      end

      let(:valid_params) do
        {
          organization: {
            id: '',
            name: Forgery(:name).company_name,
            description: Forgery(:lorem_ipsum).words(15),
            website_url: "https://#{Forgery('internet').domain_name}",
            cover_attributes: {
              image: fixture_file_upload(ImageSample.for_size('415x115')),
              crop_x: '0',
              crop_y: '0',
              crop_w: '415',
              crop_h: '115',
              rotate: '0'
            }
          }
        }
      end

      it 'Success response' do
        expect(response).to be_successful
      end

      it 'Cover url present' do
        expect(current_user.reload.organization&.cover&.image&.url).not_to be_nil
      end
    end

    context 'when invalid organization Cover' do
      before do
        put :update, format: :json, params: invalid_params
      end

      let(:invalid_params) do
        {
          organization: {
            id: '',
            name: Forgery(:name).company_name,
            description: Forgery(:lorem_ipsum).words(15),
            website_url: "https://#{Forgery('internet').domain_name}",
            cover_attributes: {
              image: fixture_file_upload(ImageSample.for_size('400x100')),
              crop_x: '0',
              crop_y: '0',
              crop_w: '415',
              crop_h: '115',
              rotate: '0'
            }
          }
        }
      end

      it 'Response status 422' do
        expect(response.status).to eq(422)
      end

      it 'Correct validation message' do
        expect(response.body).to include('should be 415x115 minimum')
      end

      it 'Cover not set' do
        expect(current_user.organization).to be_nil
      end
    end
  end
end
