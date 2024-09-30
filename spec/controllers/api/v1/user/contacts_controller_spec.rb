# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ContactsController do
  let(:current_user) { create(:user) }
  let!(:contact1) { create(:contact, for_user: current_user, name: 'b1') }
  let!(:contact2) { create(:contact, for_user: current_user, name: 'a2') }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      before do
        contact1
        contact2
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
            expect(response.body).to include contact1.name
            expect(response.body).to include contact2.name
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
          end
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response_body['pagination']['total_pages']).to eq(2)
            expect(response_body['pagination']['current_page']).to eq(1)
          end
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { limit: 1, offset: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response_body['pagination']['total_pages']).to eq(2)
            expect(response_body['pagination']['current_page']).to eq(2)
          end
        end

        context 'when given status: "contact" for search' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { status: 0 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response_body['pagination']['count']).to eq(2)
            expect(response.body).to include 'contact'
          end
        end

        context 'when given status: "subscription" for search' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { status: 1 }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body.empty?)
          end
        end

        context 'when given name for search' do
          let(:response_body) { JSON.parse(response.body) }

          it 'does not fail and returns valid json' do
            get :index, params: { q: 'a' }, format: :json

            expect(response).to be_successful
            expect { JSON.parse(response.body) }.not_to raise_error, response.body
            expect(response.body).to include 'a2'
          end
        end
      end
    end

    describe 'POST create:' do
      let(:valid_params) do
        {
          email: 'test@test.com',
          public_display_name: 'name name'
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

        it 'creates new contact' do
          expect do
            post :create, params: valid_params, format: :json
            new_contact = Contact.last
            expect(response).to be_successful
            expect(new_contact.name).to eq 'name name'
            expect(new_contact.email).to eq valid_params[:email]
          end.to change(Contact, :count).by(1)
        end
      end
    end

    describe 'PUT update:' do
      let(:valid_params) do
        {
          id: contact1.id,
          contact: {
            name: 'test1',
            email: 'test1@test.com'
          }
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

        it 'updates studio' do
          put :update, params: valid_params, format: :json
          contact = Contact.find(valid_params[:id])
          expect(response).to be_successful
          expect(contact.name).to eq valid_params[:contact][:name]
          expect(contact.email).to eq valid_params[:contact][:email]
        end
      end
    end

    describe 'DELETE destroy:' do
      let(:valid_params) do
        {
          ids: [contact1.id, contact2.id]
        }
      end

      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present and 1 ids' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'destroys contacts' do
          delete :destroy, params: valid_params, format: :json
          contacts = Contact.where(id: valid_params[:ids])
          expect(response).to be_successful
          expect(contacts.empty?)
        end
      end
    end

    describe 'POST :import_from_csv' do
      let(:valid_params) do
        { file: fixture_file_upload(Dir[File.expand_path Rails.root.join('spec/fixtures/contacts/*')].sample) }
      end

      before do
        request.headers['Authorization'] = auth_header_value
        expect(Contact.count).to eq(2)
        post :import_from_csv, params: valid_params, format: :json
      end

      it 'imports contact' do
        expect(Contact.count).to eq(3)
      end
    end
  end
end
