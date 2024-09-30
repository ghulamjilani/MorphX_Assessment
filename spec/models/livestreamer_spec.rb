# frozen_string_literal: true
require 'spec_helper'

describe Livestreamer do
  it { is_expected.to belong_to(:session) }
  it { is_expected.to belong_to(:participant) }
end
