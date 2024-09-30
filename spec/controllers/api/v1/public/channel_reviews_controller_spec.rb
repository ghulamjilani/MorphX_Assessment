# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ChannelReviewsController do
  let(:channel) { create(:listed_channel) }
  let!(:comment) do
    create(:session_review_with_mandatory_rates, commentable: create(:immersive_session, channel: channel))
  end

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when channel exsits' do
        before { get :index, params: { channel_id: channel.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
