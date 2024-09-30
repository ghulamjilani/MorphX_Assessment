# frozen_string_literal: true

json.id                               sender.id
json.name                             sender.public_display_name
json.path                             sender.relative_path
json.avatar                           sender.avatar_url
json.sender_has_owned_channels        sender.has_owned_channels?
