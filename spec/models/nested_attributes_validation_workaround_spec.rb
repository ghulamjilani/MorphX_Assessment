# frozen_string_literal: true

require 'spec_helper'

# TODO: perhaps this may all go away when we found a better of dealing with nested_attributes
# without recreating them on every create/update
describe 'Nested Attributes Validation Workaround when' do
  describe ChannelLink do
    # @see channels_controller: create and update actions
    it { is_expected.not_to validate_presence_of(:channel) }
  end
end
