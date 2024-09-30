# frozen_string_literal: true
require 'spec_helper'

describe MarketingTools::OptInModal, type: :model do
  it { is_expected.to belong_to(:channel) }
  it { is_expected.to belong_to(:system_template) }
  it { is_expected.to have_many(:opt_in_modal_submits) }
end
