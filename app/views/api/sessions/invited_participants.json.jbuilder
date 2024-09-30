# frozen_string_literal: true

envelope json do
  json.session_invited_participants do
    json.array! @session.session_invited_immersive_participantships do |obj|
      json.user_info do
        user = obj.user
        json.display_name user.public_display_name
        json.email user.email
        json.avatar_url user.avatar_url
      end
      json.participant_info do
        json.status invited_participant_status(obj.participant)
        json.has_in_contacts? current_user.has_contact?(obj.user_id)
      end
    end
  end

  json.session_invited_livestreams do
    json.array! @session.session_invited_livestream_participantships do |obj|
      json.user_info do
        user = obj.user
        json.display_name user.public_display_name
        json.email user.email
        json.avatar_url user.avatar_url
      end
      json.participant_info do
        json.status invited_livestream_status(obj.participant)
        json.has_in_contacts? current_user.has_contact?(obj.user_id)
      end
    end
  end

  json.session_invited_co_presenters do
    json.array! @session.session_invited_immersive_co_presenterships do |obj|
      json.user_info do
        user = obj.user
        json.display_name user.public_display_name
        json.email user.email
        json.avatar_url user.avatar_url
      end
      json.participant_info do
        json.status invited_co_presenters_status(obj.presenter)
        json.has_in_contacts? current_user.has_contact?(obj.user_id)
      end
    end
  end
end
