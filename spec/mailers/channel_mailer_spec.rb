# frozen_string_literal: true

require 'spec_helper'

describe ChannelMailer do
  describe '#channel_updated' do
    let(:admin) { mock_model(Admin, email: 'admin1@example.com') }
    let(:channel) do
      create(:channel,
             category: create(:channel_category, name: 'Dance'),
             presenter: create(:presenter),
             title: 'Channel was title')
    end

    let(:mail) do
      channel.title = 'Channel new title'
      channel.category = create(:channel_category, name: 'Music')
      described_class.channel_updated(channel.changed_notifiable_attrs, channel, 'admin@example.com')
    end

    it 'renders the subject' do
      expect(mail.subject).to eq 'Channel change notification'
    end
  end
end
