# frozen_string_literal: true

module Sender
  class Slack
    ISSUE_REPORT_CHANNEL_WEBHOOK_URL = Rails.application.credentials.backend.dig(:webhooks, :slack, :issue_report)

    def self.notify(message, channel_webhook_url)
      body = { text: message }.to_json
      begin
        client = Excon.new(channel_webhook_url, debug_request: !Rails.env.production?,
                                                debug_response: !Rails.env.production?)
        client.request(expects: [200], method: :post, body: body)
      rescue StandardError => e
        Airbrake.notify(e)
      end
    end
  end
end
