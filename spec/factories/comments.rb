# frozen_string_literal: true
FactoryBot.define do
  factory :comment do
    user
    association :commentable, factory: :immersive_session
    body do
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
  end

  factory :aa_stub_comments, parent: :comment
end
