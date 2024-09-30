# frozen_string_literal: true
FactoryBot.define do
  factory :channel_invited_presentership do
    presenter
    association :channel, factory: :listed_channel
  end

  factory :channel_invited_presentership_accepted, parent: :channel_invited_presentership do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED }
  end

  factory :channel_invited_presentership_pending, parent: :channel_invited_presentership do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING }
  end

  factory :channel_invited_presentership_rejected, parent: :channel_invited_presentership do
    status { ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED }
  end

  factory :aa_stub_channel_invited_presenterships, parent: :channel_invited_presentership
end
