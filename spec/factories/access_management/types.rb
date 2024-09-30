# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_type, class: 'AccessManagement::Type' do
    name { %w[Admin Creator Member].sample }
  end

  factory :admin_access_management_type, parent: :access_management_type do
    name { 'Admin' }
  end

  factory :creator_access_management_type, parent: :access_management_type do
    name { 'Creator' }
  end

  factory :aa_stub_access_management_types, parent: :access_management_type
end
