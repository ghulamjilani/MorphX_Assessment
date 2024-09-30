# frozen_string_literal: true
FactoryBot.define do
  factory :authy_record do
    user
    authy_user_id { rand(1..30_000).to_s }
    status { AuthyRecord::Statuses::ALL.sample }
    cellphone { '971126326' }
    country_code { '380' }
  end
end
