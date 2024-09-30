# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe UpdateUserAgent do
  before do
    Sidekiq::Testing.inline! do
      described_class.perform_async(1,
                                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/601.5.17 (KHTML, like Gecko) Version/9.1 Safari/601.5.17',
                                    '192.168.1.105')
    end
  end

  it 'works' do
    expect(UserAgent.count).to eq(1)
  end

  it { expect(UserAgent.last.last_time_used_at).to be_truthy }
end
