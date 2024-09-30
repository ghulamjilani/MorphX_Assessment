# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::GroupsMembersChannel do
  it { is_expected.to belong_to(:channel) }
  it { is_expected.to belong_to(:groups_member) }
end
