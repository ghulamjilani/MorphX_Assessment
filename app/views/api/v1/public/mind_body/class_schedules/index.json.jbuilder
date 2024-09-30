# frozen_string_literal: true

envelope json do
  json.array! @class_schedules do |class_schedule|
    json.partial! 'class_schedule_short', class_schedule: class_schedule
    json.staff do
      json.partial! 'api/v1/public/mind_body/staffs/staff_short', staff: class_schedule.staff
    end
    json.location do
      json.partial! 'api/v1/public/mind_body/locations/location_short', location: class_schedule.location
    end
    json.class_description do
      json.partial! 'api/v1/public/mind_body/class_descriptions/class_description_short',
                    class_description: class_schedule.class_description
    end
    json.class_rooms do
      json.array! class_schedule.class_rooms do |class_room|
        json.partial! 'api/v1/public/mind_body/class_rooms/class_room_short', class_room: class_room
      end
    end
    json.unite_sessions do
      json.array! class_schedule.sessions do |session|
        json.partial! 'api/v1/public/sessions/session_short', model: session
      end
    end
  end
end
