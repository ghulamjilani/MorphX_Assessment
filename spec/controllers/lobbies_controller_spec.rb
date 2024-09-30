# frozen_string_literal: true

require 'spec_helper'

describe LobbiesController do
  let!(:lobby_time) { 15 }
  let(:session) do
    session = build(:published_session, start_at: 10.minutes.from_now, pre_time: lobby_time, status: 'published')
    session.send(:assign_room)
    session.send(:set_slug)
    session.save(validate: false)
    session
  end
  let(:current_presenter) { session.organizer }
  let(:current_co_presenter) { create(:session_co_presentership, session: session).presenter.user }
  let(:current_participant) { create(:session_participation, session: session).participant.user }

  before do
    sign_in current_presenter, scope: :user
  end

  describe "GET 'show'" do
    render_views

    it 'returns http success' do
      get :show, params: { id: session.room.id, vidyo: true }
      expect(response.code).to eq '200'
    end

    it 'returns http success' do
      get :show, params: { id: session.room.id }
      expect(response.code).to eq '302'
    end
  end

  describe "POST 'start_streaming'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.start_at = Time.zone.now - 1.minute
      session.save(validate: false)
      post :start_streaming, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404' do
      session.update(start_at: Time.zone.now + 1.minute)
      post :start_streaming, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'be_right_back'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :be_right_back_on, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end
  end

  describe "POST 'be_right_back_off'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :be_right_back_off, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end
  end

  describe "POST 'disable_control'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :disable_control, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404 with co_presenter' do
      session.update(start_at: Time.zone.now - 1.minute)
      sign_in current_co_presenter, scope: :user
      post :disable_control, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end

    it 'returns 404' do
      sign_in current_co_presenter, scope: :user
      post :disable_control, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'allow_control'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :allow_control, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404 with co_presenter' do
      session.update(start_at: Time.zone.now - 1.minute)
      sign_in current_co_presenter, scope: :user
      post :allow_control, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end

    it 'returns 404' do
      sign_in current_co_presenter, scope: :user
      post :allow_control, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'mute'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :mute, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404' do
      sign_in current_participant, scope: :user
      post :mute, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'unmute'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update_attribute(:start_at, Time.zone.now - 1.minute)
      post :unmute, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404' do
      sign_in current_participant, scope: :user
      post :unmute, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'start_video'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :start_video, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404' do
      sign_in current_participant, scope: :user
      post :start_video, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end

  describe "POST 'stop_video'" do
    before do
      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'returns http success' do
      session.update(start_at: Time.zone.now - 1.minute)
      post :stop_video, params: { id: session.room.id }
      expect(response.code).to eq '200'
    end

    it 'returns 404' do
      sign_in current_participant, scope: :user
      post :stop_video, params: { id: session.room.id }
      expect(response.code).to eq '404'
    end
  end
end
