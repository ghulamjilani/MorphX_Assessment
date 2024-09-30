# frozen_string_literal: true
FactoryBot.define do
  factory :admin_log do
    association :admin
    association :loggable, factory: :listed_channel
  end

  factory :aa_stub_logs, parent: :admin_log
end
