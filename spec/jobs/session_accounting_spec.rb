# frozen_string_literal: true

require 'spec_helper'

describe SessionAccounting do
  let(:session) { build(:immersive_session, duration: 30) }

  it 'expect' do
    expect do
      session.save!
    end.to change(described_class.jobs, :size).by(1)
  end

  it 'is queued' do
    session.duration = 60
    expect do
      session.save!
    end.to change(described_class.jobs, :size).by(1)
  end
end
