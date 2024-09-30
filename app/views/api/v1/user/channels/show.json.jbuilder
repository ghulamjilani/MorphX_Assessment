# frozen_string_literal: true

envelope json, (@status || 200), (@channel.pretty_errors if @channel.errors.present?) do
  json.partial! 'channel', channel: @channel
end
