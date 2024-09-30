# frozen_string_literal: true

envelope json do
  json.follows do
    json.array! @follows do |follow|
      json.partial! 'follow', follow: follow
      json.followable do
        json.followable_type follow.followable_type
        json.partial! follow.followable_type.downcase, model: follow.followable
      end
    end
  end
end
