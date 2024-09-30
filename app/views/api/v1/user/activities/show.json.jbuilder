# frozen_string_literal: true

envelope json, (@status || 200), (@activity.pretty_errors if @activity.errors.present?) do
  if @activity&.trackable
    json.activity do
      json.partial! 'activity', activity: @activity
      json.trackable do
        entity = @activity.trackable_type.downcase
        json.set!(entity) do
          json.partial! "api/v1/public/#{entity.pluralize}/#{entity}", model: @activity.trackable
        end
      end
    end
  end
end
