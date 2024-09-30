# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::AccessManagement::OrganizationMembershipsController do
  let(:current_user) { create(:stripe_user_with_card) }
  let(:organization) { create(:organization, user: current_user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
      current_user.update(current_organization_id: organization.id)
    end

    describe 'GET index:' do
      context 'when given no params' do
        let!(:member) { create(:organization_membership, organization: organization) }

        render_views

        it 'does not fail and returns valid json' do
          get :index, params: { organization_id: organization.id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include member.user.public_display_name
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given search query param' do
        let!(:member) { create(:organization_membership, organization: organization) }

        render_views

        it 'does not fail and returns valid json' do
          get :index, params: { organization_id: organization.id, q: member.user.email.split('@').first }, format: :json
          expect(response).to be_successful
          expect(response.body).to include member.user.public_display_name
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'POST create:' do
      context 'when service_subscription disabled' do
        context 'when given new user params' do
          let(:email) { Forgery('internet').email_address }
          let!(:credential_group) { create(:access_management_group) }
          let(:credential_group_member) { create(:access_management_group, code: :member) }

          render_views

          before do
            Rails.application.credentials.global[:service_subscriptions][:enabled] = false
          end

          it 'does not fail and returns valid json' do
            credential_group_member
            post :create,
                 params: { organization_id: organization.id, email: email, group_ids: [credential_group.id], first_name: Forgery('name').first_name, last_name: Forgery('name').last_name }, format: :json
            expect(response).to be_successful
            expect(response.body).to include email
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end
      end

      context 'when service_subscription enabled' do
        context 'when given new user params' do
          let(:email) { Forgery('internet').email_address }
          let!(:credential_group) { create(:access_management_group) }
          let(:credential_group_member) { create(:access_management_group, code: :member) }
          let(:plan) { create(:service_plan_with_stripe_data) }
          let(:service_subscription) do
            subscription = create(:stripe_service_subscription, user: current_user, stripe_plan: plan, status: 'trialing')
            subscription_attrs = {
              customer: current_user.stripe_customer_id,
              # default_tax_rates: [tax], # Skip For now because we don't have tax
              items: [{ plan: plan.stripe_id }]
            }
            stripe_subscription = Stripe::Subscription.create(subscription_attrs)
            subscription.stripe_id = stripe_subscription.id
            subscription.save
            create(:feature_parameter, plan_feature: create(:plan_feature, code: :manage_admins), value: 'true', plan_package: subscription.plan_package)
            create(:feature_parameter, plan_feature: create(:plan_feature, code: :manage_creators), value: 'true', plan_package: subscription.plan_package)
            subscription
          end

          render_views

          before do
            Rails.application.credentials.global[:service_subscriptions][:enabled] = true
          end

          after do
            Rails.application.credentials.global[:service_subscriptions][:enabled] = false
          end

          it 'fail if no subscription' do
            credential_group_member
            post :create,
                 params: { organization_id: organization.id, email: email, group_ids: [credential_group.id], first_name: Forgery('name').first_name, last_name: Forgery('name').last_name }, format: :json
            expect(response).not_to be_successful
          end

          it 'success if subscription present' do
            credential_group_member
            service_subscription
            post :create,
                 params: { organization_id: organization.id, email: email, group_ids: [credential_group.id], first_name: Forgery('name').first_name, last_name: Forgery('name').last_name }, format: :json
            expect(response).to be_successful
          end
        end
      end
    end

    describe 'PUT update:' do
      context 'when given no params' do
        let!(:member) { create(:organization_membership, organization: organization) }
        let!(:credential_group) { create(:access_management_group) }
        let(:credential_group_member) { create(:access_management_group, code: :member) }

        render_views

        it 'does not fail and returns valid json' do
          credential_group_member
          put :update, params: { organization_id: organization.id, id: member.id, group_ids: [credential_group.id] }, format: :json
          expect(response).to be_successful
          expect(response.body).to include member.user.email
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end

    describe 'DELETE destroy:' do
      context 'when given no params' do
        let!(:member) { create(:organization_membership, organization: organization) }

        render_views

        it 'does not fail and returns valid json' do
          delete :destroy, params: { organization_id: organization.id, id: member.id }, format: :json
          expect(response).to be_successful
        end
      end
    end
  end
end
