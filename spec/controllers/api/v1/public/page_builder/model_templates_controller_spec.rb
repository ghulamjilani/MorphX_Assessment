# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::PageBuilder::ModelTemplatesController do
  let(:model_template) { create(:pb_model_template) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      before do
        get :show, params: { id: model_template.id, model_type: model_template.model_type, model_id: model_template.model_id }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(response.body).to include model_template.model_id }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end
  end
end
