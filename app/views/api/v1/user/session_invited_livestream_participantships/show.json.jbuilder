# frozen_string_literal: true

envelope json, (@status || 200), (@participantship.pretty_errors if @participantship.errors.present?) do
  json.participantship do
    json.partial! 'participantship', participantship: @participantship

    json.user do
      json.cache! @participantship.participant.user, expires_in: 1.day do
        json.extract! @participantship.participant.user, :id, :public_display_name, :relative_path, :avatar_url
      end
    end

    json.session do
      json.cache! @participantship.session, expires_in: 1.day do
        json.extract! @participantship.session, :id, :always_present_title, :start_at, :channel_id, :presenter_id
      end
    end
  end
end
