# frozen_string_literal: true

FactoryBot.define do
  factory :unread_notification, class: 'Mailboxer::Notification' do
    subject { Forgery(:lorem_ipsum).words(8) }

    body { Forgery(:lorem_ipsum).paragraphs(2) }
    association :notified_object, factory: :user
    recipients { |notification| [notification.notified_object] }
    created_at { 2.days.ago }
    expires { 2.days.from_now }
    after(:create) do |notification|
      receipt = ::Mailboxer::Receipt.new
      receipt.notification = notification
      receipt.is_read = false
      receipt.receiver = notification.notified_object
      receipt.save!
    end
  end
end
