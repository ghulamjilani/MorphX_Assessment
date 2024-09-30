# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe DeleteOldRecords do
  it 'does not fail' do
    session = create(:published_session)
    session.created_at = 2.months.ago
    session.save(validate: false)
    Sidekiq::Testing.inline! { described_class.perform_async }
    expect(Session.count).to be_zero
  end
end
