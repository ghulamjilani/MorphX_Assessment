# frozen_string_literal: true

envelope json, (@status || 200), (@staff.pretty_errors if @staff.errors.present?) do
  json.staff do
    json.partial! 'staff', staff: @staff
  end
end
