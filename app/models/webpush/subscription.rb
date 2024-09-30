# frozen_string_literal: true
class Webpush::Subscription < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  self.table_name = 'webpush_subscriptions'
  belongs_to :user

  def send_message(title, body, tag, url)
    Webpush.payload_send(
      message: {
        title: title,
        body: body,
        tag: tag,
        icon: '/apple-touch-icon.png',
        url: url
      }.to_json,
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
      vapid: {
        subject: url,
        public_key: Rails.application.credentials.backend.dig(:initialize, :webpush, :public_key),
        private_key: Rails.application.credentials.backend.dig(:initialize, :webpush, :private_key)
      },
      ssl_timeout: 5, # value for Net::HTTP#ssl_timeout=, optional
      open_timeout: 5, # value for Net::HTTP#open_timeout=, optional
      read_timeout: 5 # value for Net::HTTP#read_timeout=, optional
    )
  end
end
