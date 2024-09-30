# frozen_string_literal: true
FactoryBot.define do
  factory :session do
    duration { (15..180).step(5).to_a.sample }
    # service_type { 'rtmp' }
    custom_description_field_label { 'Special instructions' }
    start_at { 4.hours.from_now.beginning_of_hour }
    channel { create(:approved_channel) }
    presenter { channel.organizer.presenter }
    title { "#{Forgery(:lorem_ipsum).words(4, random: true)} #{rand(999)}" }
    description { Forgery(:lorem_ipsum).paragraphs(2, random: true) }
    shares_count { rand(200) }
    donate_title_as_singular { PaypalDonation::TitleAsSingular::ALL.sample }
    ffmpegservice_account { create(:ffmpegservice_account, organization_id: channel.organization_id) }
    livestream_purchase_price { 28.0 + (rand(99) / 100.0) }
    level { Session.valid_levels.sample }
    adult { false }
    age_restrictions { 0 }

    private { false }

    featured { true }

    promo_weight { rand(100) }
    promo_start { [nil, 7.days.ago].sample }
    promo_end { 7.days.from_now if promo_start.present? }
    cover do
      if Rails.env.test?
        File.open(ImageSample.for_size('415x115'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/channel/*')].sample)
      end
    end
  end

  factory :immersive_session, parent: :session do
    immersive_type { Session::ImmersiveTypes::GROUP }
    immersive_purchase_price { 28.0 + (rand(99) / 100.0) }
    livestream_purchase_price { nil }
    min_number_of_immersive_and_livestream_participants { 2 }
    max_number_of_immersive_participants { 10 }
  end

  factory :immersive_session_on_listed_channel, parent: :immersive_session do
    channel { create(:listed_channel) }
  end

  factory :livestream_session, parent: :session do
    livestream_purchase_price { 28.0 + (rand(99) / 100.0) }
    min_number_of_immersive_and_livestream_participants { 2 }
    service_type { 'rtmp' }
  end

  factory :published_livestream_session, parent: :livestream_session do
    channel { create(:listed_channel) }
    status { Session::Statuses::PUBLISHED }
  end

  factory :recorded_session, parent: :session do
    start_at { rand(2..61).hours.from_now.beginning_of_hour }
    level { Session.valid_levels.sample }

    private { false }

    featured { true }
    adult { false }
    age_restrictions { 0 }
    status { Session::Statuses::PUBLISHED }
    immersive_type { Session::ImmersiveTypes::GROUP }
    immersive_purchase_price { 23.0 + (rand(99) / 100.0) }
    recorded_purchase_price { 23.0 + (rand(99) / 100.0) }
    min_number_of_immersive_and_livestream_participants { 2 }
    max_number_of_immersive_participants { 10 }
    channel { create(:listed_channel) }
    after(:create) do |session|
      room = session.room
      FactoryBot.create(:video_published, user_id: room.presenter_user_id, room_id: room.id)
      room.update_attribute(:vod_is_fully_ready, true)
      start_at = rand(1000).hours.ago
      session.update_attribute(:start_at, start_at)
      room.update_attribute(:actual_start_at, start_at)
      room.update_attribute(:actual_end_at, session.duration.minutes.since(start_at))
    end
  end

  factory :cancelled_session, parent: :immersive_session do
    cancelled_at { Time.zone.now }
    abstract_session_cancel_reason
  end

  factory :free_trial_immersive_session, parent: :published_session do
    free_trial_for_first_time_participants { true }
    immersive_free_slots { 2 }
  end

  factory :free_trial_livestream_session, parent: :published_session do
    free_trial_for_first_time_participants { true }
    immersive_free_slots { 2 }
    livestream_free_slots { 2 }
    livestream_purchase_price { 14.99 }
  end

  factory :pending_completely_free_session, parent: :immersive_session do
    requested_free_session_reason { 'please please please please' }
    immersive_free { true }
    livestream_free { false }
    immersive_purchase_price { 0 }
    livestream_purchase_price { nil }
    recorded_purchase_price { 12.33 }
    # after(:build) do |session|
    #   # to skip livestream cost validation errors
    #   session.requested_free_session = true
    # end
    after(:create) do |session|
      session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING
      session.save(validate: false)

      # session.create_session_waiting_list!
    end
  end

  factory :completely_free_session, parent: :immersive_session do
    requested_free_session_satisfied_at { Time.zone.now }
    immersive_free { true }
    livestream_free { true }
    immersive_purchase_price { 0 }
    livestream_purchase_price { 0 }
    recorded_purchase_price { 12.33 }
    # after(:build) do |session|
    #   # to skip livestream cost validation errors
    #   session.requested_free_session = true
    # end
    after(:create) do |session|
      session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED
      session.save(validate: false)

      # session.create_session_waiting_list!
    end
  end

  factory :one_on_one_session, parent: :published_session do
    adult { false }
    age_restrictions { 0 }
    duration { 15 }
    level { Session.valid_levels.sample }
    immersive_type { Session::ImmersiveTypes::ONE_ON_ONE }
    immersive_purchase_price { 14.99 }
  end

  factory :session_with_livestream_only_delivery, parent: :published_session do
    adult { false }
    age_restrictions { 0 }
    custom_description_field_label { 'Special instructions' }
    custom_description_field_value { 'fsdfas' }
    immersive_purchase_price { nil }
    livestream_purchase_price { 14.99 }
    recorded_purchase_price { nil }
    min_number_of_immersive_and_livestream_participants { 2 }
    immersive_type { nil }
    # level nil
    level { Session.valid_levels.sample }
    service_type { 'rtmp' }
  end

  factory :immersive_session_with_recorded_delivery, parent: :published_session do
    recorded_purchase_price { 11.99 }
  end

  factory :published_session, parent: :immersive_session do
    donate_video_tab_content_in_markdown_format do
      'Visit our [kickstarter campaign](https://www.kickstarter.com/projects/1523379957/oculus-rift-step-into-the-game)'
    end
    donate_video_tab_options_in_csv_format { '1,5,10' }
    after(:create) do |session|
      # session.create_session_waiting_list!

      session.status = 'published'
      session.save!
    end

    channel { create(:listed_channel) }
  end

  factory :published_session_without_waiting, parent: :published_session do
    after(:create) do |session|
      session.session_waiting_list.delete
    end
  end

  factory :private_published_session, parent: :immersive_session do
    private { true }
    after(:create) do |session|
      session.min_number_of_immersive_and_livestream_participants.to_i.times do
        session.session_invited_immersive_participantships.create(participant: create(:participant))
      end
      # session.create_session_waiting_list!

      session.status = 'published'
      session.save!
    end
  end
  factory :start_now_session, parent: :immersive_session do
    start_at { 2.seconds.from_now }
    start_now { true }
    after(:create) do |session|
      # session.create_session_waiting_list!

      session.status = 'published'
      session.save!
    end
  end

  factory :immersive_session_fake, parent: :immersive_session do
    channel { create(:channel_fake) }
    fake { true }
  end

  factory :session_with_chat, parent: :published_livestream_session do
    allow_chat { true }
  end

  factory :aa_stub_sessions, parent: :immersive_session
  factory :aa_stub_paid_sessions, parent: :immersive_session
end
