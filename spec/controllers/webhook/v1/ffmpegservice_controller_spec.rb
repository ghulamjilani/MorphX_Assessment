# frozen_string_literal: true

require 'spec_helper'

describe Webhook::V1::FfmpegserviceController do
  describe 'GET :create' do
    it 'does not fail' do
      get :create, params: { data: { event: 'test' } }
      expect(response).to be_successful
    end
  end

  describe 'POST :create' do
    it 'does not fail' do
      post :create, params: { data: { event: 'test' } }
      expect(response).to be_successful
    end
  end
end
