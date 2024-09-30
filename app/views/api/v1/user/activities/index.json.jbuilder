# frozen_string_literal: true

envelope json do
  json.activities do
    json.array! @activities do |activity|
      if activity&.trackable
        json.activity do
          json.partial! 'activity', activity: activity
          json.trackable do
            json.partial! 'trackable', trackable: activity.trackable
            json.partial! "trackable_#{activity.trackable_type.parameterize.underscore.singularize}",
                          trackable: activity.trackable
          end
        end
      end
    end
  end
end
