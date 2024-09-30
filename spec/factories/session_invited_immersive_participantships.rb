# frozen_string_literal: true
FactoryBot.define do
  factory :session_invited_immersive_participantship do
    participant
    association :session, factory: :immersive_session
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING }
  end

  factory :accepted_session_invited_immersive_participantship, parent: :session_invited_immersive_participantship do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED }
  end

  factory :rejected_session_invited_immersive_participantship, parent: :session_invited_immersive_participantship do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED }
  end
end
