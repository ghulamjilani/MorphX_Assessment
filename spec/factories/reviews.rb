# frozen_string_literal: true
FactoryBot.define do
  factory :session_review_with_mandatory_rates, class: 'Review' do
    user
    title { '' }
    overall_experience_comment do
      [
        'looks really good',
        'that was very exciting',
        "I'm impressed",
        'That presenter knows what he is talking about',
        'cant wait to see the next session',
        'Totally recommended!',
        'Best anyone could ask for',
        'Great session',
        'My recommendation !!!',
        'Proof style and substance can go together',
        'perfection',
        'Amazing ending',
        'Wonderful experience',
        'Warmly recommended'
      ].sample
    end
    association :commentable, factory: :immersive_session
    after(:build) do |review|
      session = review.commentable
      # only passed sessions could be rated/commented on
      session.start_at = Time.zone.now.beginning_of_hour - 1.day - Session.where("now() > (start_at + (INTERVAL '1 minute' * duration))").count.days
      def session.not_in_the_past
        # skip it
      end
      session.save!

      session.immersive_participants << FactoryBot.create(:participant, user: review.user)

      create_mandatory_rates review.user, session
    end
  end

  factory :recording_review_with_mandatory_rates, class: 'Review' do
    user
    title { '' }
    overall_experience_comment do
      [
        'looks really good',
        'that was very exciting',
        "I'm impressed",
        'That presenter knows what he is talking about',
        'cant wait to see the next session',
        'Totally recommended!',
        'Best anyone could ask for',
        'Great session',
        'My recommendation !!!',
        'Proof style and substance can go together',
        'perfection',
        'Amazing ending',
        'Wonderful experience',
        'Warmly recommended'
      ].sample
    end
    association :commentable, factory: :recording_published
    after(:build) do |review|
      recording = review.commentable

      create_mandatory_rates review.user, recording
    end
  end

  factory :session_review_from_presenter, class: 'Review' do
    association :commentable, factory: :immersive_session
    user { commentable.organizer }
    title { '' }
    overall_experience_comment do
      [
        'looks really good',
        'that was very exciting',
        "I'm impressed",
        'That presenter knows what he is talking about',
        'cant wait to see the next session',
        'Totally recommended!',
        'Best anyone could ask for',
        'Great session',
        'My recommendation !!!',
        'Proof style and substance can go together',
        'perfection',
        'Amazing ending',
        'Wonderful experience',
        'Warmly recommended'
      ].sample
    end
    technical_experience_comment do
      [
        'looks really good',
        'that was very exciting',
        "I'm impressed",
        'That presenter knows what he is talking about',
        'cant wait to see the next session',
        'Totally recommended!',
        'Best anyone could ask for',
        'Great session',
        'My recommendation !!!',
        'Proof style and substance can go together',
        'perfection',
        'Amazing ending',
        'Wonderful experience',
        'Warmly recommended'
      ].sample
    end
    after(:build) do |review|
      session = review.commentable
      session.start_at = Time.zone.now.beginning_of_hour - 1.day - Session.where("now() > (start_at + (INTERVAL '1 minute' * duration))").count.days
      def session.not_in_the_past
        # skip it
      end
      session.save!

      session.rate((1..5).to_a.sample, session.organizer, Session::RateKeys::IMMERSS_EXPERIENCE)
    end
  end

  factory :aa_stub_channel_reviews, parent: :session_review_with_mandatory_rates
  factory :aa_stub_reviews, parent: :session_review_with_mandatory_rates
end
