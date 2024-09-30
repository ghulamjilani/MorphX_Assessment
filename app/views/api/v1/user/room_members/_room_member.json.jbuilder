# frozen_string_literal: true

json.extract! room_member, :id, :abstract_user_id, :abstract_user_type,
              :display_name, :room_id, :kind, :has_control,
              :mic_disabled, :video_disabled,
              :backstage, :joined, :pinned,
              :banned, :ban_reason_id
json.guest                  room_member.guest?
json.created_at             room_member.created_at.utc.to_fs(:rfc3339)
json.updated_at             room_member.updated_at.utc.to_fs(:rfc3339)
