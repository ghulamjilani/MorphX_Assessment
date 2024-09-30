# frozen_string_literal: true
FactoryBot.define do
  factory :attached_list, class: 'Shop::AttachedList' do
    list
    model { create(:session) }
  end
  factory :aa_stub_attached_lists, parent: :attached_list
end
