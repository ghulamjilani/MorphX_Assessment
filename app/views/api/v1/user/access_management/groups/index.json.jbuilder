# frozen_string_literal: true

envelope json do
  json.groups do
    json.array! @groups do |group|
      json.partial! 'group', group: group
    end
  end
end
