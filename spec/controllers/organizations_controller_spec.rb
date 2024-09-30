# frozen_string_literal: true

require 'spec_helper'

describe OrganizationsController do
  describe 'POST :leave' do
    before do
      sign_in current_user, scope: :user
      request.env['HTTP_REFERER'] = 'http://localhost:3000/whatever'
    end

    context 'when given content manager' do
      let(:organization_membership) { create(:organization_membership) }
      let(:current_user) { organization_membership.user }
      let(:organization) { organization_membership.organization }

      it 'works' do
        post :leave, params: { id: organization.id }

        expect(response).to be_redirect
        expect(current_user.organization_memberships_participants.count).to eq(0)
      end
    end

    context 'when given channel presenter' do
      let(:channel_invited_presentership) { create(:channel_invited_presentership) }
      let(:organization) { channel_invited_presentership.channel.organization }
      let(:current_user) { channel_invited_presentership.presenter.user }

      it 'works' do
        post :leave, params: { id: organization.id }

        expect(response).to be_redirect
        expect(current_user.organization_memberships_participants.count).to eq(0)
        expect(organization.channel_invited_presenterships.count).to eq(0)
      end
    end
  end

  describe 'PUT :update' do
    before do
      sign_in current_user, scope: :user
    end

    context 'when valid organization Cover' do
      before do
        put :update, format: :json, params: valid_params
      end

      let(:organization_membership) { create(:organization_membership_administrator) }
      let(:current_user) { organization_membership.user }
      let(:organization) { organization_membership.organization }

      let(:valid_params) do
        {
          id: organization.id,
          organization: {
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
        expect(organization&.cover&.image&.url).not_to be_nil
      end
    end

    context 'when invalid organization Cover' do
      before do
        put :update, format: :json, params: invalid_params
      end

      let(:organization_membership) { create(:organization_membership_administrator) }
      let(:current_user) { organization_membership.user }
      let(:organization) { organization_membership.organization }

      let(:invalid_params) do
        {
          id: organization.id,
          organization: {
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
        expect(organization.cover).to be_nil
      end
    end
  end
end
