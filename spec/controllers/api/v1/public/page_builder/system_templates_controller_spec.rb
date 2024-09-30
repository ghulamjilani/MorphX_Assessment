# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::PageBuilder::SystemTemplatesController do
  let(:system_template) { create(:pb_system_template) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      before do
        get :show, params: { id: system_template.id, name: system_template.name }, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(response.body).to include system_template.name }

      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end
  end
end
