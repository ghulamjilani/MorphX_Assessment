# frozen_string_literal: true
FactoryBot.define do
  factory :session_invited_immersive_co_presentership do
    presenter
    association :session, factory: :immersive_session
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING }
  end

  factory :accepted_session_invited_immersive_co_presentership, parent: :session_invited_immersive_co_presentership do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED }
  end

  factory :rejected_session_invited_immersive_co_presentership, parent: :session_invited_immersive_co_presentership do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED }
  end
end
