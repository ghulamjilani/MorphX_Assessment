# frozen_string_literal: true

require 'spec_helper'

describe LobbiesHelper do
  describe '#donate_video_tab_content' do
    let(:helper1) do
      helper = Object.new
      helper.extend described_class
      helper
    end

    it 'works' do
      actual = helper1.donate_video_tab_content Session.new(donate_video_tab_content_in_markdown_format: 'Visit out [kickstarter campaign](https://www.google.com)')
      expect(actual).to eq(%(<p>Visit out <a href="https://www.google.com" target="_blank">kickstarter campaign</a></p>\n))
    end
  end
end
