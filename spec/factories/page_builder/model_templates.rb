# frozen_string_literal: true
FactoryBot.define do
  factory :pb_model_template, class: '::PageBuilder::ModelTemplate' do
    model { create(:channel) }
    body { {}.to_json }
  end

  factory :aa_stub_page_builder_model_templates, parent: :pb_model_template
end
