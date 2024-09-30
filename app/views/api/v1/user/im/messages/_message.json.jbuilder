# frozen_string_literal: true

json.id                             message.id.to_s
json.conversation_id                message.conversation_id
json.conversation_participant_id    message.conversation_participant_id
json.body                           message.body
json.modified_at                    message.modified_at&.utc&.to_fs(:rfc3339)
json.deleted_at                     message.deleted_at&.utc&.to_fs(:rfc3339)
json.created_at                     message.created_at.utc.to_fs(:rfc3339)
