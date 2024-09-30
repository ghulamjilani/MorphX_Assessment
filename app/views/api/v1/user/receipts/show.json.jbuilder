# frozen_string_literal: true

envelope json, (@status || 200), (@receipt.pretty_errors if @receipt.errors.present?) do
  json.receipt do
    json.partial! 'receipt', receipt: @receipt
    json.conversation_id @receipt.message.conversation_id
    json.message do
      json.partial! 'message', message: @receipt.message
    end
  end
end
