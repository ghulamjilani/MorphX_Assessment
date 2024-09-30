# frozen_string_literal: true
FactoryBot.define do
  factory :channel do
    sequence(:title) { |n| "Test Channel ##{n} #{Forgery::Name.company_name}" }
    association :organization, factory: :organization_with_subscription
    presenter { nil }
    description { Forgery(:lorem_ipsum).paragraphs(2) }
    show_on_home { true }
    channel_type { ChannelType.instructional || FactoryBot.create(:instructional_channel_type) }
    channel_location { 'Austin, TX' }
    approximate_start_date { (Time.zone.now + 5.days).to_date.inspect }
    tag_list do
      %w[animals architecture art asia australia autumn baby band barcelona beach berlin bike bird birds birthday black
         blackandwhite blue bw california canada canon car cat chicago china christmas church city clouds color concert dance day de dog
         england europe fall family fashion festival film florida flower flowers food football france friends fun garden geotagged germany girl
         graffiti green halloween hawaii holiday house india instagramapp iphone iphoneography island italia italy japan kids la lake landscape
         light live london love macro me mexico model museum music nature new newyork newyorkcity night nikon nyc ocean old paris park party people
         photo photography photos portrait raw red river rock san sanfrancisco scotland sea seattle show sky snow spain spring square squareformat
         street summer sun sunset taiwan texas thailand tokyo travel tree trees trip uk unitedstates urban usa vacation vintage washington water wedding
         white winter woman yellow zoo].sample(3)
    end
    association :category, factory: :channel_category
    im_conversation_enabled { true }
    show_documents { true }
    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
  end

  factory :channel_with_image, parent: :channel do
    after(:create) do |channel|
      FactoryBot.create(:main_channel_image, channel: channel)
    end
  end

  factory :pending_channel, parent: :channel do
    status { Channel::Statuses::PENDING_REVIEW }
  end

  factory :approved_channel, parent: :channel do
    show_on_home { true }
    after(:create) { |channel| channel.submit_for_review! && channel.approve! }
  end

  factory :listed_channel, parent: :approved_channel do
    after(:create, &:list!)
  end

  factory :archived_channel, parent: :listed_channel do
    archived_at { 1.day.ago }
  end

  factory :rejected_channel, parent: :channel do
    after(:create) do |channel|
      channel.rejection_reason = 'not in compliance with our Code and policies'
      channel.status = Channel::Statuses::REJECTED
      channel.save!
    end
  end

  factory :approved_channel_with_image, parent: :channel_with_image do
    after(:create) { |channel| channel.submit_for_review! && channel.approve! && channel.list! }
  end

  factory :rejected_channel_with_image, parent: :channel_with_image do
    after(:create) do |channel|
      channel.rejection_reason = 'not in compliance with our Code and policies'
      channel.status = Channel::Statuses::REJECTED
      channel.save!
    end
  end

  factory :channel_fake, parent: :channel do
    fake { true }
    organization { create(:organization_fake) }
  end

  factory :aa_stub_channels, parent: :channel
end
