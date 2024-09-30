# frozen_string_literal: true

module ControllerConcerns::EverflowTracking
  extend ActiveSupport::Concern

  included do
    before_action :set_everflow_cookie
  end

  def set_everflow_cookie
    if Rails.application.credentials.backend.dig(:initialize, :everflow, :enabled) && params[:ef_transaction_id].present?
      begin
        # For some reason random requests to Everflow::Network::Transaction.retrieve fail with error
        # "No click associated to that transaction id found"
        # But after some time Everflow::Network::Transaction.retrieve returns 200 OK
        # So lets add workaround and set cookie in any case
        transaction = Everflow::Network::Transaction.retrieve(params[:ef_transaction_id])
        offer = Everflow::Network::Offer.retrieve(transaction[:click][:relationship][:offer][:network_offer_id])
        duration = offer[:session_duration]&.hours&.from_now
      rescue StandardError => e
        Rails.logger.debug params[:ef_transaction_id]
        Rails.logger.debug e.inspect
      ensure
        # Set cookie to 24 hours if something went wrong
        duration ||= 24.hours.from_now
        cookies[:ef_transaction_id] = {
          value: params[:ef_transaction_id],
          expires: duration
        }
      end
    end
  end
end
