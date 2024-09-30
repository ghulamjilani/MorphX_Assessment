# frozen_string_literal: true
require 'spec_helper'

describe Payout do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:payment_transactions) }
end
