# frozen_string_literal: true
FactoryBot.define do
  factory :opt_in_modal_submit, class: 'MarketingTools::OptInModalSubmit' do
    data { Forgery('internet').email_address }
    association :user
    association :opt_in_modal
  end

  factory :aa_stub_opt_in_modal_submits, parent: :opt_in_modal_submit
end
