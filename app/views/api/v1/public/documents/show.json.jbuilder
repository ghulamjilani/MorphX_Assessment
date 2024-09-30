# frozen_string_literal: true

envelope json do
  json.partial! 'api/v1/public/documents/document', document: @document
end
