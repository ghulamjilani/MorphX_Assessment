# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::PageBuilder::SystemTemplateAbility do
  let(:subject) { described_class.new(current_user) }
  let(:pb_system_template) { create(:pb_system_template) }

  describe '#create' do
    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { is_expected.not_to be_able_to :create, pb_system_template }
    end

    context 'when given platform owner' do
      let(:current_user) { create(:user, platform_role: :platform_owner) }

      it { is_expected.to be_able_to :create, pb_system_template }
    end
  end
end
