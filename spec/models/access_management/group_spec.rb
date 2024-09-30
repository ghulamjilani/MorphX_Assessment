# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::Group do
  subject(:group) { build(:access_management_group, system: false) }

  it { expect(group).to validate_presence_of(:name) }
  it { expect(group).to validate_presence_of(:organization_id) }

  describe '#validates_uniqueness_of :name' do
    context 'when has organization' do
      before { group.organization_id = 1 }

      it { expect(group).to validate_uniqueness_of(:name).scoped_to(:organization_id) }
    end

    context 'when has not organization' do
      before { group.organization_id = nil }

      it { expect(group).not_to validate_uniqueness_of(:name) }
    end
  end

  describe '#validates_exclusion_of :name' do
    context 'when system group exists' do
      before do
        create(:access_management_group, system: true, name: 'Channel Admin')
        group.organization_id = 1
      end

      it { expect(group).to validate_exclusion_of(:name).in_array(['Channel Admin']) }
    end
  end

  describe '#validates_presence_of :organization_id' do
    context 'when system' do
      before { group.system = true }

      it { expect(group).not_to validate_presence_of(:organization_id) }
    end

    context 'when not system' do
      before { group.system = false }

      it { expect(group).to validate_presence_of(:organization_id) }
    end
  end

  it { expect(group).to belong_to(:organization) }
  it { expect(group).to have_many(:groups_credentials) }
  it { expect(group).to have_many(:groups_members) }
  it { expect(group).to have_many(:credentials) }
  it { expect(group).to have_many(:users) }
end
