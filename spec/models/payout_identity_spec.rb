# frozen_string_literal: true
require 'spec_helper'

describe PayoutIdentity do
  it { is_expected.to belong_to(:payout_method) }
end
