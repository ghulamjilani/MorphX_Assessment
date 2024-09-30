# frozen_string_literal: true
FactoryBot.define do
  factory :guest, class: 'Guest' do
    public_display_name { Forgery(:name).full_name }
    ip_address { Forgery(:internet).ip_v4 }
    visitor_id { SecureRandom.uuid }
    user_agent { 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Safari/537.36' }
    secret { random_secret }
  end

  factory :aa_stub_guests, parent: :guest
end
