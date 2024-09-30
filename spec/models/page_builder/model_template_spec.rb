# frozen_string_literal: true
require 'spec_helper'

describe PageBuilder::ModelTemplate do
  let(:model_template) { create(:pb_model_template) }

  describe 'Validations' do
    context 'when model template is valid' do
      it { expect(model_template).to be_valid }
    end

    describe 'model validation' do
      context 'when model is not set' do
        let(:model_template) { build(:pb_model_template, model: nil) }

        it { expect(model_template).not_to be_valid }
      end

      context 'when model is of unsupported type' do
        let(:model_template) { build(:pb_model_template, model: create(:recording)) }

        it { expect(model_template).not_to be_valid }
      end
    end

    describe 'body validation' do
      context 'when body is not set' do
        let(:model_template) { build(:pb_model_template, body: '') }

        it { expect(model_template).not_to be_valid }
      end
    end
  end

  describe '#assign_organization' do
    let(:model) { create(:channel) }
    let(:model_template) { build(:pb_model_template, model: model) }

    before do
      model_template.send(:assign_organization)
    end

    it { expect { model_template.send(:assign_organization) }.not_to raise_error }

    context 'when model is a channel' do
      it { expect(model_template.organization_id).to eq(model.organization_id) }
    end

    context 'when model is an organization' do
      let(:model) { create(:organization) }

      it { expect(model_template.organization_id).to eq(model.id) }
    end
  end
end
