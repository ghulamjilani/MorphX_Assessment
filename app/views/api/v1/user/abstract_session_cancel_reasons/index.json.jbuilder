# frozen_string_literal: true

envelope json do
  json.abstract_session_cancel_reasons do
    json.array! @session_cancel_reasons do |session_cancel_reason|
      json.partial! 'abstract_session_cancel_reason', abstract_session_cancel_reason: session_cancel_reason
    end
  end
end
