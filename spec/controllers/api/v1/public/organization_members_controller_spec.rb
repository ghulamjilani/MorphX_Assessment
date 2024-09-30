# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::OrganizationMembersController do
  let(:channel) { create(:listed_channel) }
  let(:channel_members) { create_list(:channel_invited_presentership_accepted, 10, channel: channel) }

  render_views

  describe '.json request format' do
    describe 'GET show:' do
      context 'when channel exsits' do
        before do
          channel_members
          get :index, params: { organization_id: channel.organization.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
