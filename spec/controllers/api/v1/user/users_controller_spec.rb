# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::UsersController do
  let(:user) { create(:user_with_presenter_account) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: 'current' }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: 'current' }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        context 'when current user has current organization' do
          let(:user) do
            membership = create(:organization_membership)
            user = membership.user
            user.update!(current_organization: membership.organization)
            user.reload
          end

          it { expect(response).to be_successful }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when jwt has expired' do
          let(:auth_header_value) do
            Auth::Jwt::Encoder.new(
              type: Auth::Jwt::Types::USER_TOKEN,
              model: create(:auth_user_token),
              options: { expires_at: 10.minutes.ago }
            ).jwt
          end

          it { expect(response.status).to be 401 }

          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end

      it 'updates last_sign_in_at' do
        expect do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: 'current' }, format: :json
          user.reload
        end.to(change(user, :last_sign_in_at))
      end
    end

    describe 'PUT update:' do
      let(:request_params) do
        {
          id: 'current',
          user: {
            first_name: 'John',
            last_name: 'Doe',
            display_name: 'John Doe',
            gender: %w[male female hidden].sample
          }
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: request_params, format: :json
          expect(response).to have_http_status :unauthorized
        end

        context 'when correct reset password token present' do
          before do
            put :update,
                params: { id: 'current', reset_password_token: user.send_reset_password_instructions, user: { password: 'Abcdef123!', password_confirmation: 'Abcdef123!' } }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when wrong reset password token present' do
          before do
            put :update,
                params: { id: 'current', reset_password_token: 'wrong', user: { password: 'Abcdef123!', password_confirmation: 'Abcdef123!' } }, format: :json
          end

          it { expect(response.status).to be 404 }
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          put :update, params: request_params, format: :json
          user.reload
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it 'updates user attributes' do
          request_params[:user].each do |attribute_name, value|
            expect(user.attributes[attribute_name.to_s]).to eq value
          end
        end
      end
    end
  end
end
