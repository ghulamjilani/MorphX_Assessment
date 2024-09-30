# frozen_string_literal: true
FactoryBot.define do
  factory :dropbox_material do
    association :abstract_session, factory: :immersive_session
    path { "/im#{rand(9000)}.jpg" }
    mime_type { 'image/jpeg' }
    data { nil }
  end
end
