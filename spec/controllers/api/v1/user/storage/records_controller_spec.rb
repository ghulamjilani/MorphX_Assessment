# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Storage::RecordsController do
  let(:current_user) { storage_record.organization.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:storage_record) { create(:storage_record_attachment) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      let(:params) do
        {
          model_type: storage_record.model_type,
          object_type: storage_record.object_type,
          relation_type: storage_record.relation_type,
          order: 'asc',
          limit: 15,
          offset: 0
        }
      end

      before do
        storage_record.update_columns(byte_size: rand(666_666))
        request.headers['Authorization'] = auth_header_value
        get :index, params: params, format: :json
      end

      it { expect(response).to be_successful }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

      it { expect(response.body).to include(storage_record.byte_size.to_s) }
    end
  end
end
