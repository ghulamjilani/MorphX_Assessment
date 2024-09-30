# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Auth::RegistrationsController do
  describe '.json request format' do
    render_views

    describe 'POST create' do
      context 'when no gender and birthdate skipping' do
        let(:params) do
          {
            user: {
              first_name: Forgery(:name).first_name,
              last_name: Forgery(:name).last_name,
              birthdate: '07/01/1959',
              gender: %w[male female].sample,
              email: (SecureRandom.alphanumeric(3) + Forgery('internet').email_address).downcase,
              password: 'Asd123456!@#'
            }
          }.tap do |params|
            params[:password_confirmation] = params[:password]
          end
        end

        before do
          post :create, params: params, format: :json
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:current_user)).not_to be_blank }
        it { expect(assigns(:auth_user_token)).not_to be_blank }
      end

      context 'when gender and birthdate skipped' do
        let(:params) do
          {
            user: {
              first_name: Forgery(:name).first_name,
              last_name: Forgery(:name).last_name,
              email: (SecureRandom.alphanumeric(3) + Forgery('internet').email_address).downcase,
              password: 'Asd123456!@#'
            }
          }.tap do |params|
            params[:password_confirmation] = params[:password]
          end
        end

        before do
          Rails.application.credentials.global[:skip_gender_and_birthdate] = true
          post :create, params: params, format: :json
        end

        after do
          Rails.application.credentials.global[:skip_gender_and_birthdate] = false
        end

        it { expect(response).to be_successful }

        it { expect(assigns(:current_user)).not_to be_blank }

        it { expect(assigns(:auth_user_token)).not_to be_blank }
      end

      context 'when given signup token' do
        let(:signup_token) { create(:signup_token) }
        let(:params) do
          {
            user: {
              first_name: Forgery(:name).first_name,
              last_name: Forgery(:name).last_name,
              birthdate: '07/01/1959',
              gender: %w[male female].sample,
              email: (SecureRandom.alphanumeric(3) + Forgery('internet').email_address).downcase,
              password: 'Asd123456!@#'
            },
            signup_token: {
              token: signup_token.token
            }
          }.tap do |params|
            params[:password_confirmation] = params[:password]
          end
        end

        before do
          post :create, params: params, format: :json
        end

        it { expect(response).to be_successful }

        it { expect(assigns(:current_user)).not_to be_blank }

        it { expect(assigns(:signup_token)).not_to be_blank }

        it { expect(assigns(:current_user).can_use_wizard).to eq(signup_token.can_use_wizard) }
      end
    end
  end
end
