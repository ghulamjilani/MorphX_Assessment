# frozen_string_literal: true

envelope json do
  json.partial! 'api/v1/user/documents/document', document: @document
end
