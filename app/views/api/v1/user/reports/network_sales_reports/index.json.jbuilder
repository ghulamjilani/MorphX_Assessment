# frozen_string_literal: true

envelope json do
  json.array! @reports do |report|
    json.organization do
      json.partial! 'api/v1/user/reports/organization', organization_id: report[:_id][:organization_id]
    end
    json.channel do
      json.partial! 'api/v1/user/reports/channel', channel_id: report[:_id][:channel_id]
    end
    json.purchased_item do
      json.partial! 'api/v1/user/reports/purchased_item', item_id: report[:_id][:purchased_item_id], item_type: report[:_id][:purchased_item_type]
    end
    json.cost report[:_id][:cost].to_i / 100.0
    json.type ::Reports::V1::RevenuePurchasedItem::FORMATTED_TYPES[report[:_id][:type].to_sym]
    json.qty report[:qty]
    json.gross_income report[:gross_income].to_i / 100.0
    json.commission report[:commission].to_i / 100.0
    json.income report[:income].to_i / 100.0
    json.refund report[:refund].to_i / 100.0
    json.refund_system report[:refund_system].to_i / 100.0
    json.refund_creator report[:refund_creator].to_i / 100.0
    json.total report[:total].to_i / 100.0
  end
end
