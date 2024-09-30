# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::RecordingAbility do
  let(:ability) { described_class.new(current_user) }

  describe '#see_recording' do
    let(:recording) { create(:recording) }
    let(:current_user) { recording.channel.organizer }

    it { expect(ability).to be_able_to :see_recording, recording }
  end
end
