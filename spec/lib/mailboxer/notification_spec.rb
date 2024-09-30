# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Notification do
  let(:user) { create(:user) }

  it 'works' do
    expect do
      Immerss::Mailboxer::Notification.save_with_receipt(user: user, subject: 'subject title', sender: nil,
                                                         body: 'some body mesage')
    end.to change { Mailboxer::Receipt.count }.from(0).to(1)
  end

  describe '.save_with_receipt' do
    before do
      Immerss::Mailboxer::Notification.save_with_receipt(user: user, subject: 'subject title', sender: nil,
                                                         body: 'some body mesage')
    end

    it { expect(Mailboxer::Receipt.first.is_read).to be false }
    it { expect(Mailboxer::Receipt.first.receiver).to eq(user) }
  end
end
