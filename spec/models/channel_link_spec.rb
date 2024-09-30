# frozen_string_literal: true
require 'spec_helper'

describe ChannelLink, 'validations' do
  let(:channel) { create(:channel) }

  before { VCR.insert_cassette("#{described_class.to_s.underscore}_#{self.class.description.parameterize}") }

  it 'allows only unique url combinations' do
    channel.channel_links.create!(url: 'https://soundcloud.com/this-american-life/504-how-i-got-into-college')

    expect do
      channel.channel_links.create!(url: 'https://soundcloud.com/this-american-life/504-how-i-got-into-college')
    end.to raise_error(/Url has already been taken/)

    channel.channel_links.create!(url: 'https://soundcloud.com/this-american-life/500-500')
  end
end
