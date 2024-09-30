# frozen_string_literal: true
require 'spec_helper'

describe ChannelCategory do
  let(:channel) { create(:channel) }
  let(:default_category) { described_class.default_category }
  let(:uncategorized_channel) { create(:channel, category_id: default_category.id) }
  let(:category_with_channels) { channel.category }

  describe '#destroy' do
    it 'assigns category channels to default category' do
      category_with_channels.destroy
      channel.reload
      expect(channel.category_id == described_class.default_category.id).to be_truthy
    end

    it "doesn't allow to destroy default category" do
      default_category
      expect { default_category.destroy }.not_to(change { described_class.default_category.id })
    end
  end

  describe '#reassign_channels_to_default_cat' do
    it 'assigns category channels to default category' do
      category_with_channels.reassign_channels_to_default_cat
      channel.reload
      expect(channel.category_id).to eq(default_category.id)
    end
  end
end
