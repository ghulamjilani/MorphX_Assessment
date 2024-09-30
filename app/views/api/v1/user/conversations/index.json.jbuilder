# frozen_string_literal: true

envelope json do
  json.conversations do
    json.array! @conversations do |conversation|
      json.cache! [conversation], expires_in: 1.day do
        json.conversation do
          json.partial! 'conversation', conversation: conversation
          json.originator_id conversation.originator.id
          json.participants do
            json.array! conversation.participants do |participant|
              json.partial! 'participant', participant: participant
            end
          end
          receipt = conversation.receipts_for(current_user).not_deleted.last
          json.last_receipt nil unless receipt
          if receipt.present?
            json.last_receipt do
              json.partial! 'api/v1/user/receipts/receipt', receipt: receipt
              json.message do
                json.partial! 'api/v1/user/receipts/message', message: receipt.message
              end
            end
          end
        end
      end
    end
  end
end
