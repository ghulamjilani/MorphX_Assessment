# frozen_string_literal: true

json.channels do
  json.array! @accumulator do |v|
    json.channel_name v.first
    json.channel_color @colors.pop

    json.sessions do
      json.array! v.last do |session|
        json.max_number_of_immersive_participants session.max_number_of_immersive_participants
        json.relative_path                        session.relative_path
        json.immersive_type                       session.immersive_type
        json.title                                session.always_present_title
        json.start_at                             session.start_at.in_time_zone(used_timezone)
        json.duration                             session.duration
        json.popover_data                         session.popover_data(used_time_format)
      end
    end
  end
end
