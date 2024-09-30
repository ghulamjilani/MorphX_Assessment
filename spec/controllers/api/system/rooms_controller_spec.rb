# frozen_string_literal: true

require 'spec_helper'

describe ::Api::System::RoomsController do
  describe '.json request format' do
    describe 'POST status_changed:' do
      let(:room) { create(:room) }

      it 'does not fail' do
        room
        expect_any_instance_of(Room).to receive(:cable_status_notifications)
        post :status_changed, params: { id: room.id }, format: :json
        expect(response).to be_successful
      end
    end
  end
end
