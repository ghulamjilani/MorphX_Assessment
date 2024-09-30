# frozen_string_literal: true

json.cache! ['app/views/api/v1/user/reports/_purchased_item', item_id, item_type], expires_in: 1.day do
  item = item_type.classify.constantize.find_by(id: item_id)
  json.id item_id
  json.type item_type
  if item
    case item_type
    when 'Session', 'Video', 'Recording'
      json.name item.title
      json.url item.absolute_path
      creator = item.organizer
      json.creator do
        json.id creator&.id
        json.name creator&.public_display_name
        json.url creator&.absolute_path
      end
    when 'StripeDb::Plan'
      json.name item.im_name
    end
  end
end
