# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::GroupsCredential do
  it { is_expected.to belong_to(:group) }
  it { is_expected.to belong_to(:credential) }
end
