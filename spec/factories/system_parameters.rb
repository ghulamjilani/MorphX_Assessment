# frozen_string_literal: true
FactoryBot.define do
  factory :system_parameter do
    key { 'max_number_of_immersive_participants' }
    value { 1.99 }
  end

  factory :aa_stub_system_parameters, parent: :system_parameter
end
