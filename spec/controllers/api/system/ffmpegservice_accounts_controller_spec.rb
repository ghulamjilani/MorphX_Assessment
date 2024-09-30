# frozen_string_literal: true

require 'spec_helper'

describe ::Api::System::FfmpegserviceAccountsController do
  describe '.json request format' do
    describe 'POST update_stream_status:' do
      let(:ffmpegservice_account) { create(:ffmpegservice_account) }

      it 'does not fail' do
        expect_any_instance_of(FfmpegserviceAccount).to receive(:stream_status_changed)
        post :update_stream_status, params: { id: ffmpegservice_account.id }, format: :json
        expect(response).to be_successful
      end
    end
  end
end
