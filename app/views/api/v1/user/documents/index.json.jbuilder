# frozen_string_literal: true

envelope json do
  json.array! @documents do |document|
    json.partial! 'api/v1/user/documents/document', document: document
  end
end
