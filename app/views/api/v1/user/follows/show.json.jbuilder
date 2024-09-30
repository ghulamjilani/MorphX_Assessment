# frozen_string_literal: true

envelope json, (@status || 200), (@follow.pretty_errors if @follow.errors.present?) do
  json.follow do
    json.partial! 'follow', follow: @follow
    json.followable do
      followable_classname = @followable.class.name.downcase
      json.set!(followable_classname) do
        json.partial! "api/v1/public/#{followable_classname.pluralize}/#{followable_classname}", model: @followable
      end
    end
  end
end
