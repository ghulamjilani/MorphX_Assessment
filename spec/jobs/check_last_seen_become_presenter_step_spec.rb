# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe CheckLastSeenBecomePresenterStep do
  it 'does not fail' do
    user = [create(:user), create(:presenter).user].sample
    Sidekiq::Testing.inline! do
      described_class.perform_async(user.id)
    end
  end
end
