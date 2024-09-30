# frozen_string_literal: true
require 'spec_helper'

describe Contact do
  it { is_expected.to belong_to(:for_user) }
  it { is_expected.to belong_to(:contact_user) }
end
