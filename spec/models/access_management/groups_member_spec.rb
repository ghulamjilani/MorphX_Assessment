# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::GroupsMember do
  it { is_expected.to belong_to(:group) }
  it { is_expected.to belong_to(:organization_membership) }
  it { is_expected.to have_one(:user) }
  it { is_expected.to have_many(:groups_members_channels) }
  it { is_expected.to have_many(:channels) }
  it { is_expected.to validate_uniqueness_of(:organization_membership_id).scoped_to(:access_management_group_id) }
end
