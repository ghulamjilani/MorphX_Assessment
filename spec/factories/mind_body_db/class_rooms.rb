# frozen_string_literal: true
FactoryBot.define do
  factory :mind_body_db_class_site, class: 'MindBodyDb::ClassRoom' do
    active { false }
  end

  factory :aa_stub_mind_body_db_class_sites, parent: :mind_body_db_class_site
end
