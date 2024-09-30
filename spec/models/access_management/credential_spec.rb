# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::Credential do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:type) }
end
