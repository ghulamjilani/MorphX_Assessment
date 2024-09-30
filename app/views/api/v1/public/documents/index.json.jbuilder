# frozen_string_literal: true

envelope json do
  json.array! @documents do |document|
    json.partial! 'api/v1/public/documents/document', document: document
  end
end
