# frozen_string_literal: true
FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { 'abcdef' }
    password_confirmation { 'abcdef' }
    role { :superadmin }
  end

  factory :aa_stub_admins, parent: :admin
end
