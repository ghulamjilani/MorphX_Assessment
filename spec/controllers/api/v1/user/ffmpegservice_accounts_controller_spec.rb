# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::FfmpegserviceAccountsController do
  let(:current_organization) { create(:organization) }
  let(:current_user) { current_organization.user }
  let(:organization2) { create(:organization) }
  let(:studio1) { create(:studio, organization: current_organization) }
  let(:studio2) { create(:studio, organization: current_organization) }
  let(:studio_room_st1_1) { create(:studio_room, studio: studio1) }
  let(:studio_room_st1_2) { create(:studio_room, studio: studio1) }
  let(:studio_room_st2_1) { create(:studio_room, studio: studio2) }
  let(:studio_room_st2_2) { create(:studio_room, studio: studio2) }
  let(:assigned_ffmpegservice_account_st1_r1) do
    create(:ffmpegservice_account, organization: current_organization, studio_room: studio_room_st1_1)
  end
  let(:assigned_ffmpegservice_account_st1_r2) do
    create(:ffmpegservice_account, organization: current_organization, studio_room: studio_room_st1_2)
  end
  let(:assigned_ffmpegservice_account_st2_r1) do
    create(:ffmpegservice_account, organization: current_organization, studio_room: studio_room_st2_1)
  end
  let(:assigned_ffmpegservice_account_st2_r2) do
    create(:ffmpegservice_account, organization: current_organization, studio_room: studio_room_st2_2)
  end
  let(:unassigned_ffmpegservice_account) { create(:ffmpegservice_account, organization: current_organization) }
  let(:unaccessible_ffmpegservice_account) { create(:ffmpegservice_account, organization: organization2) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        assigned_ffmpegservice_account_st1_r1
        assigned_ffmpegservice_account_st1_r2
        assigned_ffmpegservice_account_st2_r1
        assigned_ffmpegservice_account_st2_r2
        unassigned_ffmpegservice_account
        unaccessible_ffmpegservice_account
      end

      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          it 'does not fail and returns valid json' do
            get :index, params: {}, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include assigned_ffmpegservice_account_st1_r1.custom_name
            expect(response.body).to include assigned_ffmpegservice_account_st1_r2.custom_name
            expect(response.body).to include assigned_ffmpegservice_account_st2_r1.custom_name
            expect(response.body).to include assigned_ffmpegservice_account_st2_r2.custom_name
            expect(response.body).to include unassigned_ffmpegservice_account.custom_name
            expect(response.body).not_to include unaccessible_ffmpegservice_account.custom_name
          end
        end

        context 'when given studio_id param' do
          it 'does not fail and returns valid json' do
            get :index, params: { studio_id: studio1.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include assigned_ffmpegservice_account_st1_r1.custom_name
            expect(response.body).to include assigned_ffmpegservice_account_st1_r2.custom_name
            expect(response.body).not_to include assigned_ffmpegservice_account_st2_r1.custom_name
            expect(response.body).not_to include assigned_ffmpegservice_account_st2_r2.custom_name
            expect(response.body).not_to include unassigned_ffmpegservice_account.custom_name
            expect(response.body).not_to include unaccessible_ffmpegservice_account.custom_name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(2)
          end
        end

        context 'when given studio_room_id param' do
          it 'does not fail and returns valid json' do
            get :index, params: { studio_room_id: studio_room_st1_1.id }, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include assigned_ffmpegservice_account_st1_r1.custom_name
            expect(response.body).not_to include assigned_ffmpegservice_account_st1_r2.custom_name
            expect(response.body).not_to include assigned_ffmpegservice_account_st2_r1.custom_name
            expect(response.body).not_to include assigned_ffmpegservice_account_st2_r2.custom_name
            expect(response.body).not_to include unassigned_ffmpegservice_account.custom_name
            expect(response.body).not_to include unaccessible_ffmpegservice_account.custom_name
            expect(JSON.parse(response.body)['pagination']['count']).to eq(1)
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(current_organization.ffmpegservice_accounts.count)
            expect(response_body['pagination']['total_pages']).to eq(current_organization.ffmpegservice_accounts.count)
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json
            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(current_organization.ffmpegservice_accounts.count)
            expect(response_body['pagination']['total_pages']).to eq(current_organization.ffmpegservice_accounts.count)
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: assigned_ffmpegservice_account_st1_r1.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when ffmpegservice account belongs to current organization' do
          it 'does not fail and returns valid json' do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: assigned_ffmpegservice_account_st1_r1.id }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include assigned_ffmpegservice_account_st1_r1.custom_name
          end
        end
      end
    end

    describe 'GET new:' do
      let(:wa_free_pull) { create(:ffmpegservice_account_free_pull) }
      let(:wa_free_push) { create(:ffmpegservice_account_free_push) }
      let(:wa_free_pull_reserved) { create(:ffmpegservice_account_free_pull, reserved_by: current_organization) }
      let(:wa_free_push_reserved) { create(:ffmpegservice_account_free_push, reserved_by: current_organization) }
      let(:valid_params) { { delivery_method: %w[pull push].sample } }

      context 'when JWT missing' do
        it 'returns 401' do
          get :new, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when no wa was reserved previously' do
          it 'reserves wa' do
            all_ffmpegservice_accounts = [
              wa_free_pull,
              wa_free_push
            ]

            get :new, params: valid_params, format: :json
            ffmpegservice_account = FfmpegserviceAccount.find(JSON.parse(response.body)['response']['ffmpegservice_account']['id'])
            expect(response).to be_successful
            expect(ffmpegservice_account.delivery_method).to eq valid_params[:delivery_method]
            expect(ffmpegservice_account.reserved_by_id).to eq current_organization.id
            expect(ffmpegservice_account.reserved_by_type).to eq current_organization.class.to_s
            expect(all_ffmpegservice_accounts.pluck(:id)).to include(ffmpegservice_account.id)
          end
        end

        context 'when wa was reserved previously' do
          it 'returns previously reserved wa' do
            reserved_ffmpegservice_accounts = [
              wa_free_pull_reserved,
              wa_free_push_reserved
            ]

            get :new, params: valid_params, format: :json
            ffmpegservice_account = FfmpegserviceAccount.find(JSON.parse(response.body)['response']['ffmpegservice_account']['id'])
            expect(response).to be_successful
            expect(ffmpegservice_account.delivery_method).to eq valid_params[:delivery_method]
            expect(ffmpegservice_account.reserved_by_id).to eq current_organization.id
            expect(ffmpegservice_account.reserved_by_type).to eq current_organization.class.to_s
            expect(reserved_ffmpegservice_accounts.pluck(:id)).to include(ffmpegservice_account.id)
          end
        end
      end
    end

    describe 'POST create:' do
      let(:studio_room) { create(:studio_room) }
      let(:current_organization) { studio_room.organization }
      let(:wa) { create(%i[ffmpegservice_account_free_pull ffmpegservice_account_free_push].sample, reserved_by: current_organization) }
      let(:current_service) { (wa.delivery_method == 'push') ? %w[main rtmp].sample : 'ipcam' }
      let(:valid_params) do
        {
          id: wa.id,
          custom_name: "#{current_organization.name} video source ##{rand(999)}",
          current_service: current_service,
          studio_room_id: studio_room.id
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          post :create, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'assigns ffmpegservice account' do
          post :create, params: valid_params, format: :json
          new_ffmpegservice_account = FfmpegserviceAccount.find(JSON.parse(response.body)['response']['ffmpegservice_account']['id'])
          expect(response).to be_successful
          expect(new_ffmpegservice_account.custom_name).to eq valid_params[:custom_name]
          expect(new_ffmpegservice_account.current_service).to eq valid_params[:current_service]
          expect(new_ffmpegservice_account.studio_room_id).to eq valid_params[:studio_room_id]
          expect(new_ffmpegservice_account.organization_id).to eq current_organization.id
          expect(new_ffmpegservice_account.user_id).to eq current_user.id if valid_params[:current_service] == 'main'
          expect(new_ffmpegservice_account.reserved_by_id).to be_nil
          expect(new_ffmpegservice_account.reserved_by_type).to be_nil
        end
      end
    end

    describe 'PUT update:' do
      let(:valid_params) do
        {
          id: assigned_ffmpegservice_account_st1_r1.id,
          custom_name: "#{current_organization.name} Studio ##{rand(999)}",
          studio_room_id: studio_room_st1_2.id
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          put :update, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'updates FfmpegserviceAccount' do
          put :update, params: valid_params, format: :json
          wa = FfmpegserviceAccount.find(valid_params[:id])
          expect(response).to be_successful
          expect(wa.custom_name).to eq valid_params[:custom_name]
          expect(wa.studio_room_id).to eq valid_params[:studio_room_id]
        end
      end
    end

    describe 'DELETE destroy:' do
      let!(:wa) do
        create(:ffmpegservice_account, organization_id: current_organization.id, user_id: current_user.id,
                               current_service: 'main')
      end
      let(:valid_params) { { id: wa.id } }

      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'destroys FfmpegserviceAccount' do
          delete :destroy, params: valid_params, format: :json
          wa = FfmpegserviceAccount.find_by(id: valid_params[:id])
          expect(response).to be_successful
          expect(wa.user_id).to be nil
          expect(wa.organization_id).to be nil
          expect(wa.custom_name).to be nil
          expect(wa.current_service).to be nil
        end
      end
    end
  end
end
