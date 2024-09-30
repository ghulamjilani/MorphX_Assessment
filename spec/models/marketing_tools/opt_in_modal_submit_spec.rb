# frozen_string_literal: true
require 'spec_helper'

describe MarketingTools::OptInModalSubmit, type: :model do
  it { is_expected.to belong_to(:opt_in_modal) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to allow_value('rusni@pizda.ua').for(:data) }
  it { is_expected.not_to allow_value('invalid@').for(:data) }
  it { expect { create(:opt_in_modal_submit) }.to change(Contact, :count).by(1) }
end
