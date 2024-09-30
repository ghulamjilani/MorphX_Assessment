# frozen_string_literal: true

envelope json, (@status || 200), (@group_member.pretty_errors if @group_member.errors.present?) do
  json.group_member do
    json.partial! 'group_member', group_member: @group_member
  end
end
