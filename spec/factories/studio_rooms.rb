# frozen_string_literal: true
FactoryBot.define do
  factory :studio_room do
    studio
    sequence(:name) { |n| "#{studio.name} Room ##{n} - #{Forgery('name').company_name}" }
    description { "description-#{Forgery(:lorem_ipsum).words(22)}" }
  end

  factory :aa_stub_studio_rooms, parent: :studio_room
end
