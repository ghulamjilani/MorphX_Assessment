# frozen_string_literal: true

require 'spec_helper'

describe Spa::ChannelsController do
  render_views

  describe 'GET channels/:id for guest' do
    it 'unlisted channel should redirect to root' do
      channel = create(:channel)
      get :show, params: { id: channel.slug }
      expect(response).to be_redirect
    end

    it 'listed channel should works' do
      channel = create(:listed_channel)
      get :show, params: { id: channel.slug }
      expect(response).to be_successful
    end
  end

  describe 'GET channels/:id for creator' do
    before do
      sign_in(current_user)
    end

    let(:channel) { create(:channel) }
    let!(:current_user) { channel.organizer }

    it 'unlisted channel should works' do
      get :show, params: { id: channel.slug }
      expect(response).to be_successful
    end
  end

  describe 'GET channels/:id for non creator' do
    before do
      sign_in(current_user)
    end

    let(:channel) { create(:channel) }
    let!(:current_user) { create(:user) }

    it 'unlisted channel should redirect' do
      get :show, params: { id: channel.slug }
      expect(response).to be_redirect
    end
  end
end
