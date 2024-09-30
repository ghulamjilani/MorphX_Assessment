# frozen_string_literal: true

require 'spec_helper'

describe LiveGuideChannelsAggregator do
  subject { described_class.new(sessions).result }

  before { Timecop.freeze Chronic.parse('Jan 4th, 2014 at 15:00') }

  context 'when given no sessions' do
    let(:sessions) { [] }

    it { is_expected.to eq({}) }
  end

  context 'when given 2 non-overlapping sessions' do
    let(:sessions) do
      [
        Session.new(start_at: 3.hours.from_now.beginning_of_hour, duration: 60),
        Session.new(start_at: 6.hours.from_now.beginning_of_hour, duration: 60)
      ]
    end

    its('keys.first') { is_expected.to eq('Channel #1') }
    its('keys.length') { is_expected.to eq(1) }
    its(['Channel #1']) { is_expected.to eq(sessions) }
  end

  context 'when given 2 overlapping sessions' do
    let(:session1) { Session.new(start_at: 3.hours.from_now.beginning_of_hour, duration: 120) }
    let(:session2) { Session.new(start_at: 4.hours.from_now.beginning_of_hour, duration: 30) }

    let(:sessions) do
      [
        session1, session2
      ]
    end

    its('keys.length') { is_expected.to eq(2) }
    its('keys.first') { is_expected.to eq('Channel #1') }
    its('keys.last') { is_expected.to eq('Channel #2') }

    its(['Channel #1']) { is_expected.to eq([session1]) }
    its(['Channel #2']) { is_expected.to eq([session2]) }
  end

  context 'when given 3 sessions 2 of which overlap' do
    let(:session1) { Session.new(start_at: 3.hours.from_now.beginning_of_hour, duration: 120) }
    let(:session2) { Session.new(start_at: 4.hours.from_now.beginning_of_hour, duration: 30) }
    let(:session3) { Session.new(start_at: 6.hours.from_now.beginning_of_hour, duration: 30) }

    let(:sessions) do
      [
        session1, session2, session3
      ]
    end

    its('keys.length') { is_expected.to eq(2) }
    its('keys.first') { is_expected.to eq('Channel #1') }
    its('keys.last') { is_expected.to eq('Channel #2') }

    its(['Channel #1']) { is_expected.to eq([session1, session3]) }
    its(['Channel #2']) { is_expected.to eq([session2]) }
  end
end
