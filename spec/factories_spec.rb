# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/DescribeClass
describe 'validate FactoryBot factories' do
  # rubocop:enable RSpec/DescribeClass
  FactoryBot.factories.reject { |f| f.name.eql?(:session) || f.name.eql?(:channel) }.each do |factory|
    context "with factory for :#{factory.name}" do
      let(:subject1) { create(factory.name) }

      it 'is valid' do
        expect(subject1).to be_valid, -> { subject1.errors.full_messages.join(',') } if subject1.respond_to?(:valid?)
      end
    end
  end
end
