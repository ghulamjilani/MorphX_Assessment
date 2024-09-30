# frozen_string_literal: true
FactoryBot.define do
  factory :layout_custom_code do
    name { 'foo bar' }
    content { 'fooBar' }
    description { 'Foo Bar' }
    sort_index { 1 }
    layout_position { 0 }
    enabled { true }
  end

  factory :aa_stub_layout_custom_codes, parent: :layout_custom_code
end
