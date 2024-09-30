# frozen_string_literal: true

envelope json, (@status || 200), (@group.pretty_errors if @group.errors.present?) do
  json.group do
    json.partial! 'group', group: @group
  end
end
