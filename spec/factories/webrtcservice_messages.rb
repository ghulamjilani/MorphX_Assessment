# frozen_string_literal: true
FactoryBot.define do
  factory :webrtcservice_message do
    user
    sid { Time.now.to_i }
    account_sid { 'AC6085a7b52f5917ba8e97937ef898ac83' }
    date_created { Time.zone.now }
    body do
      'Sent from your Webrtcservice trial account - Hi Nikita. Just a reminder that you have an appointment coming up at 03:11PM on Apr. 23, 2016.'
    end
    direction { 'outbound-api' }
    price { nil }
    price_unit { 'USD' }
    status { %w[delivered queued].sample }
    to { '+380971126326' }
    from { '+12057378267' }
    uri { '/2010-04-01/Accounts/AC6085a7b52f5917ba8e97937ef898ac83/Messages/SMb70ca0e76df0444da139fef015bb622e.json' }
  end
end
