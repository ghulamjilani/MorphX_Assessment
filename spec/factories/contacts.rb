# frozen_string_literal: true
FactoryBot.define do
  factory :contact do
    association :for_user, factory: :user_with_participant_account
    association :contact_user, factory: :user_with_presenter_account
    email { Forgery('internet').email_address }
    name { Forgery('name').full_name }
  end

  factory :aa_stub_contacts, parent: :contact
end
