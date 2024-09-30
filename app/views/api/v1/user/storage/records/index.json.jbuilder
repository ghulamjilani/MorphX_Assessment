# frozen_string_literal: true

envelope json, (@status || 200) do
  json.records do
    json.array! @records do |record|
      json.record do
        json.partial! 'record', record: record
      end
      json.model do
        json.partial! 'model', model: record.model
      end
    end
  end
end
