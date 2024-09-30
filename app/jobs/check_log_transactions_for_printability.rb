# frozen_string_literal: true

class CheckLogTransactionsForPrintability < ApplicationJob
  def perform(*_args)
    LogTransaction.find_each do |log_transaction|
      next if Rails.env.qa? && log_transaction.abstract_session.blank? # Darina не находит канал, потому что он с продакшна с ключами от куа, ну и вебхуки идут и на прод и на куа

      log_transaction.as_html
    rescue StandardError => e
      Airbrake.notify_sync(RuntimeError.new("log_transaction.#{log_transaction.type} failed to respond to #as_html"),
                           parameters: {
                             message: e.message,
                             attrs: log_transaction.attributes
                           })
    end
  end
end
