# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Organization::MindBody::StaffsController do
  let(:organizational_user) { current_organization.user }
  let(:staff) { create(:mind_body_db_staff_linked_to_user, user: organizational_user) }
  let(:staff1) { create(:mind_body_db_staff) }
  let(:staff2) { create(:mind_body_db_staff_linked_to_user) }
  let(:current_organization) { create(:organization) }
  let(:auth_header_value) { "Bearer #{JwtAuth.organization(current_organization)}" }
  let(:response_body) { JSON.parse(response.body) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: staff.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when staff exists' do
          before do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: staff.id }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'PUT update:' do
      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: { id: staff1.id, user_id: organizational_user.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when staff exists' do
          it 'does not fail' do
            put :update, params: { id: staff2.id, user_id: organizational_user.id }, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end

          it 'changes user_id' do
            expect do
              put :update, params: { id: staff2.id, user_id: organizational_user.id }, format: :json
              staff2.reload
            end.to change(staff2, :user_id).to(organizational_user.id)
          end
        end
      end
    end
  end
end
