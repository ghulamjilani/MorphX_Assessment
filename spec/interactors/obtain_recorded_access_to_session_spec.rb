# frozen_string_literal: true

require 'spec_helper'

describe ObtainRecordedAccessToSession do
  context 'when non-free session' do
    let(:user_with_credit_card) { create(:user_with_credit_card) }

    let(:current_user) { create(:participant, user: user_with_credit_card).user.reload }
    let(:session) { create(:immersive_session_with_recorded_delivery) }

    it 'does not fail' do
      # TODO: - need to find a way to mock braintree interface
      skip 'skip temporary'

      # interactor = described_class.new(session, current_user)
      # interactor.paid_type_is_chosen!
      # interactor.execute
      #
      # expect(interactor.success_message).not_to be_blank
      # expect(interactor.error_message).to be_blank
      #
      # expect(session.recorded_members.count).to eq(1)
    end
  end
end
