# frozen_string_literal: true
FactoryBot.define do
  factory :access_management_category, class: 'AccessManagement::Category' do
    name { 'Organization Level' }
    order { rand(999) }
  end
  factory :aa_stub_access_management_categories, parent: :access_management_category
end
