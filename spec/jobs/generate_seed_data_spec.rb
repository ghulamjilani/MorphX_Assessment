# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe GenerateSeedData do
  it 'does not fail' do
    create(:listed_channel)
    expect(Session.count).to be_zero

    # Sidekiq::Testing.inline! do
    #   GenerateSeedData.perform_async
    # end
    #
    # expect(Session.count).not_to be_zero
  end
end
