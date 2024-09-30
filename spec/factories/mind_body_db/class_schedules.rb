# frozen_string_literal: true
FactoryBot.define do
  factory :mind_body_db_class_schedule, class: 'MindBodyDb::ClassSchedule' do
    is_available { false }
  end

  factory :aa_stub_mind_body_db_class_schedules, parent: :mind_body_db_class_schedule
end
