# frozen_string_literal: true

json.logo_url             nil
json.poster_url           trackable.poster_url
json.price                trackable.purchase_price
json.purchased            trackable.recording_members.where(participant_id: current_user.try(:participant_id)).present?
