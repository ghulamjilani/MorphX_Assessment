# frozen_string_literal: true
FactoryBot.define do
  factory :ip_info_record do
    ip { format('%<a>d.%<b>d.%<c>d.%<d>d', a: rand(256), b: rand(256), c: rand(256), d: rand(256)) }
    hostname { ['No Hostname', 'nl-lw0.204vpn.net'].sample }
    city { '' }
    region { '' }
    country { %w[UA NL].sample }
    loc { %w[50.4500,30.5233 52.3824,4.8995].sample }
    org { ['AS60781 LeaseWeb Netherlands B.V.', 'AS65000'].sample }
  end
end
