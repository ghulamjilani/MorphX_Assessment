# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::SubscriptionAbility do
  let(:ability) { described_class.new(current_user) }
end
