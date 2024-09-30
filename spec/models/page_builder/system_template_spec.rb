# frozen_string_literal: true
require 'spec_helper'

describe PageBuilder::SystemTemplate do
  let(:system_template) { create(:pb_system_template) }

  describe 'Validations' do
    context 'when system template is valid' do
      it { expect(system_template).to be_valid }
    end

    describe 'name validation' do
      context 'when name is not set' do
        let(:system_template) { build(:pb_system_template, name: '') }

        it { expect(system_template).not_to be_valid }
      end

      context 'when name is already used set' do
        let(:existing_system_template) { create(:pb_system_template) }
        let(:system_template) { build(:pb_system_template, name: existing_system_template.name) }

        it { expect(existing_system_template).to be_valid }
        it { expect(system_template).not_to be_valid }
      end
    end

    describe 'body validation' do
      context 'when body is not set' do
        let(:system_template) { build(:pb_system_template, body: '') }

        it { expect(system_template).not_to be_valid }
      end
    end
  end
end
