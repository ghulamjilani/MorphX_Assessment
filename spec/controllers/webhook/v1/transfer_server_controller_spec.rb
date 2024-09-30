# frozen_string_literal: true

require 'spec_helper'

describe Webhook::V1::TransferServerController do
  describe 'POST :create' do
    let(:video) { create(:video_transfer) }
    let(:params) do
      JSON.parse(
        File.read(Rails.root.join('spec/fixtures/requests/webhook/v1/transfer_server/create_success.json'))
      ).merge({ ident: video.id })
    end

    before do
      post :create, params: params
    end

    it { expect(response).to be_successful }
  end
end
