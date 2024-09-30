# frozen_string_literal: true

FactoryBot.define do
  factory :zoom_meeting do
    association :session
  end

  factory :aa_stub_zoom_meetings, parent: :zoom_meeting
end
