# frozen_string_literal: true

require 'spec_helper'

describe Immerss::JoinHelperProxy do
  context 'when given OSX + Safari' do
    let :proxy do
      user = create(:user)
      UserAgent.create(user_id: user.id,
                       value: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/601.5.17 (KHTML, like Gecko) Version/9.1 Safari/601.5.17',
                       ip_address: '192.168.1.105',
                       last_time_used_at: 3.seconds.ago)

      described_class.new(user)
    end

    it { expect(proxy.browser.platform.mac?).to be true }
    it { expect(proxy.browser.platform.ios?).to be false }
  end

  context 'when given user without user agent' do
    let :proxy do
      user = create(:user)
      described_class.new(user)
    end

    it { expect(proxy.browser.platform.mac?).to be false }
    it { expect(proxy.browser.platform.ios?).to be false }
  end
end
