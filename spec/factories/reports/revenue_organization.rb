# frozen_string_literal: true

FactoryBot.define do
  factory :revenue_organization, class: 'Reports::V1::RevenueOrganization' do
    sequence(:channel_id) { |n| n }
    sequence(:organization_id) { |n| n }
    date { Date.today }
  end

  factory :aa_stub_revenueorganization, parent: :revenue_organization
end
