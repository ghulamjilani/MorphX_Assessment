# frozen_string_literal: true
require 'spec_helper'

describe Admin do
  it { is_expected.to have_many(:admin_logs) }
end
