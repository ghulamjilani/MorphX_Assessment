# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::PendingRefundAbility do
  let(:ability) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }

  describe '#reimburse_refund' do
    let(:session) { create(:session) }
    let(:current_user) { create(:room_member, room: session.room).abstract_user }
    let(:transaction) { create(:real_stripe_transaction, user: current_user, purchased_item: session) }
    let(:pending_refund) { create(:pending_refund, user: current_user, payment_transaction: transaction) }

    it { expect(ability).to be_able_to :reimburse_refund, pending_refund }
  end
end
