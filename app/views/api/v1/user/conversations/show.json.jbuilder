# frozen_string_literal: true

envelope json, (@status || 200), (@conversation.pretty_errors if @conversation.errors.present?) do
  json.conversation do
    json.partial! 'conversation', conversation: @conversation
    json.originator_id @conversation.originator.id
    json.participants do
      json.array! @conversation.participants do |participant|
        json.partial! 'participant', participant: participant
      end
    end
    json.receipts do
      json.array! @receipts do |receipt|
        json.receipt do
          json.partial! 'api/v1/user/receipts/receipt', receipt: receipt
          json.message do
            json.partial! 'api/v1/user/receipts/message', message: receipt.message
          end
        end
      end
    end
    @current_page = (@offset + @limit) / @limit
    json.receipts_count @receipts_count
    json.limit @limit
    json.offset @offset
    json.total_pages (@receipts_count + @limit - 1) / @limit
    json.current_page @current_page
  end
end
