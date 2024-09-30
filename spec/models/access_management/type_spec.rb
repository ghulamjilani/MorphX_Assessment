# frozen_string_literal: true
require 'spec_helper'

describe AccessManagement::Type do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to have_many(:credentials) }
end
