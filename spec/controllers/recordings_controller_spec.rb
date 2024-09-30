# frozen_string_literal: true

require 'spec_helper'

describe RecordingsController do
  describe 'POST :confirm_purchase' do
    describe 'when immersive participant' do
      before { sign_in current_user, scope: :user }

      context "when given #{ObtainTypes::PAID_RECORDING} recording" do
        let(:recording) { create(:recording_paid) }
        let(:current_user) { create(:participant).user }

        it 'raise if no payment info & system credit empty' do
          expect do
            post :confirm_purchase,
                 params: { id: recording.id, type: ObtainTypes::PAID_RECORDING }
          end.to raise_error(RuntimeError, 'not allowed')
        end

        it 'success with stripe' do
          post :confirm_purchase,
               params: { id: recording.id, type: ObtainTypes::PAID_RECORDING,
                         stripe_token: @stripe_test_helper.generate_card_token }

          expect(response).to redirect_to(recording.absolute_path)
        end
      end

      context "when given #{ObtainTypes::FREE_RECORDING} recording" do
        let(:recording) { create(:recording_published) }
        let(:current_user) { create(:participant).user }

        it 'works' do
          post :confirm_purchase, params: { id: recording.id, type: ObtainTypes::FREE_IMMERSIVE }

          expect(response).to redirect_to(recording.absolute_path)
        end
      end
    end
  end
end
