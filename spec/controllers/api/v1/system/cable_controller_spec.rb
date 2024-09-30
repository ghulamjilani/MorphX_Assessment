# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::System::CableController do
  let(:all_channels) do
    %w[UsersChannel SessionsChannel PaypalDonationsChannel PresenceImmersiveRoomsChannel PresenceSourceRoomsChannel
       PrivateLivestreamRoomsChannel PublicLivestreamRoomsChannel RoomsChannel StreamPreviewsChannel PollsChannel]
  end
  let(:channel) { all_channels.sample }
  let(:auth_header_value) do
    ActionController::HttpAuthentication::Basic.encode_credentials(ENV['PORTAL_API_LOGIN'], ENV['PORTAL_API_PASSWORD'])
  end
  let(:to_objects) do
    [
      create(:user),
      create(:room),
      create(:immersive_session)
    ]
  end
  let(:to_object) { to_objects.sample }
  let(:event) { channel.constantize::EVENTS.keys.sample }

  render_views

  describe '.json request format' do
    context 'when to_object is not present' do
      let(:params) do
        {
          channel: channel,
          event: event,
          data: { room_id: 10 }.to_json
        }
      end

      before do
        request.headers['Authorization'] = auth_header_value
        post :create, params: params, format: :json
      end

      it { expect(response).to be_successful }
    end

    context 'when to_object is present' do
      let(:params) do
        {
          channel: channel,
          event: event,
          data: { room_id: 10 }.to_json,
          to_object: { class: to_object.class.name, id: to_object.id }.to_json
        }
      end

      before do
        request.headers['Authorization'] = auth_header_value
        post :create, params: params, format: :json
      end

      it { expect(response).to be_successful }
    end
  end
end
