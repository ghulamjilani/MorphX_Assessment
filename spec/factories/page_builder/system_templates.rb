# frozen_string_literal: true
FactoryBot.define do
  factory :pb_system_template, class: '::PageBuilder::SystemTemplate' do
    name { 'homepage' }
    body { {}.to_json }
  end

  factory :aa_stub_page_builder_system_templates, parent: :pb_system_template
end
