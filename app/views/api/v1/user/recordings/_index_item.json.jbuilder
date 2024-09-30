# frozen_string_literal: true

json.recording do
  json.partial! 'api/v1/user/recordings/recording', recording: recording
end
json.channel do
  json.partial! 'api/v1/user/channels/channel', channel: recording.channel
end
json.organizer do
  json.partial! 'api/v1/public/users/user', model: recording.organizer
end
