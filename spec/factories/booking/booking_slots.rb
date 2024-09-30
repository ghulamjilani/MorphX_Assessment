# frozen_string_literal: true
FactoryBot.define do
  factory :booking_slot, class: 'Booking::BookingSlot' do
    association :user, factory: :user
    association :channel, factory: :channel
    association :booking_category, factory: :booking_category
    currency { 'USD' }
    description { Forgery(:lorem_ipsum).paragraphs(2, random: true) }
    name { Forgery(:lorem_ipsum).title(random: true) }
    replay { false }
    replay_price_cents { nil }
    slot_rules { '[{"name":"Monday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Tuesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Wednesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Thursday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Friday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Saturday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Sunday","scheduler":[{"start":"10:00","end":"18:00"}]}]' }
    week_rules { "[#{Time.now.strftime('%-V').to_i},#{(Time.now + 1.week).strftime('%-V').to_i}]" }
    tags { '[tag1,tag2]' }
  end
  factory :aa_stub_booking_booking_slots, parent: :booking_slot
end
