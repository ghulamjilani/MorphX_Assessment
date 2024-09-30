# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe Webrtcservice::RoomJobs::Usage::CollectInteractiveTimeJob do
  let(:room_member) { create(:room_member_presenter) }
  let(:usage_messages) { JSON.parse(File.read(Rails.root.join('spec/fixtures/api_responses/usage/event_receiver/messages.json'))) }
  let(:webrtcservice_response_body) do
    body = JSON.parse(File.read(Rails.root.join('spec/fixtures/api_responses/webrtcservice/video/room_participants.json')))
    body['participants'][0]['identity'] = Webrtcservice::Video::Participant.new(room_member: room_member).identity
    body
  end
  let(:webrtcservice_room) { create(:webrtcservice_room, session: room_member.session) }

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: webrtcservice_response_body.to_json, headers: {})
    quoted_base_url = Regexp.quote(::Usage.config.dig(:event_receiver, :base_url))
    stub_request(:post, Regexp.new("^#{quoted_base_url}")).to_return(status: 200, body: { response: { messages: usage_messages } }.to_json, headers: {})
  end

  it 'does not fail' do
    expect { described_class.new.perform(webrtcservice_room.id) }.not_to raise_error
  end
end
