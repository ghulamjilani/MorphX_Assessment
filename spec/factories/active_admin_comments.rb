# frozen_string_literal: true

FactoryBot.define do
  factory :active_admin_comment, class: 'ActiveAdmin::Comment' do
    namespace { 'service_admin_panel' }
    body { 'ssss' }
    association :resource, factory: :admin
    association :author, factory: :admin
  end
  factory :aa_stub_active_admin_comments, parent: :active_admin_comment
  factory :aa_stub_admin_comments, parent: :active_admin_comment
end
