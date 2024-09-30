# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ChannelsController do
  let(:channel) { create(:listed_channel) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when get list of channels' do
        before { get :index, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when channel exsits' do
        before { get :show, params: { id: channel.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
