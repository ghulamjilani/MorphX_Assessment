# frozen_string_literal: true

require 'spec_helper'

describe Webhook::V1::WebrtcserviceController do
  describe 'POST :create' do
    let(:params) do
      {
        RoomStatus: 'in-progress',
        RoomType: 'group',
        RoomSid: 'RMb2ed0bd9f12e63f217164b86b71d3186',
        RoomName: '{"s":"qa.morphx","e":"QA","i":34}',
        SequenceNumber: '0',
        StatusCallbackEvent: 'room-created',
        Timestamp: '2021-02-19T13:00:46.566Z',
        AccountSid: 'AC2df6e5baadb9e338f6f0487bcb379f67'
      }
    end

    it 'does not fail' do
      post :create, params: params
      expect(response).to be_successful
    end
  end
end
