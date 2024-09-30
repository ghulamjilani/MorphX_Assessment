# frozen_string_literal: true
require 'spec_helper'

describe PayoutMethod do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:payout_identity) }
end
