# frozen_string_literal: true

envelope json do
  json.follows do
    json.array! @follows do |follow|
      json.follow do
        json.partial! 'follow', follow: follow
        json.followable do
          followable_classname = follow.followable.class.name.downcase
          json.set!(followable_classname) do
            json.partial! "api/v1/public/#{followable_classname.pluralize}/#{followable_classname}",
                          model: follow.followable
          end
        end
      end
    end
  end
end
