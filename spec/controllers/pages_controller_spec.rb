# frozen_string_literal: true

require 'spec_helper'

describe PagesController do
  describe 'GET /help' do
    render_views
    it 'does not fail' do
      get :show, params: { id: ContentPages::HELP_CENTER.parameterize(separator: '_') }

      expect(response).to be_successful
      expect(response.body.blank?).to eq(false)
    end
  end

  describe 'GET /robots.txt' do
    let(:robots_txt_content) do
      '
      User-Agent: *
      Disallow: /
      '
    end

    before do
      File.open(Rails.root.join("config/robots.#{Rails.env}.txt"), 'w') { |f| f.write(robots_txt_content) }
    end

    it 'returns valid content' do
      get :robots

      expect(response).to be_successful
      expect(response.body).to eq(robots_txt_content)
    end
  end
end
