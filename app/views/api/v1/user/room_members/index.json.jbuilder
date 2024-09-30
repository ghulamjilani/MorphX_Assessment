# frozen_string_literal: true

envelope json do
  json.room_members do
    json.array! @room_members do |room_member|
      json.partial! 'room_member', room_member: room_member
      json.guest room_member.guest?

      json.abstract_user do
        json.partial! 'abstract_user', abstract_user: room_member.abstract_user
        json.type room_member.abstract_user_type
      end
      if room_member.ban_reason
        json.ban_reason do
          json.extract! room_member.ban_reason, :id, :name
        end
      end
    end
  end
end
