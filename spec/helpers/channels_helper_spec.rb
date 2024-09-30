# frozen_string_literal: true

require 'spec_helper'

describe ChannelsHelper do
  describe '#channel_category_collection' do
    it 'works' do
      helper = Object.new
      helper.extend described_class

      expect { helper.channel_category_collection }.not_to raise_error
    end
  end
end
