# frozen_string_literal: true
FactoryBot.define do
  factory :opt_in_modal, class: 'MarketingTools::OptInModal' do
    title { Forgery(:lorem_ipsum).title(random: true) }
    description { Forgery(:lorem_ipsum).paragraphs(1) }
    trigger_time { [60, 120, 180].sample }
    association :channel
    association :system_template, factory: :pb_system_template
  end

  factory :aa_stub_opt_in_modals, parent: :opt_in_modal
end
