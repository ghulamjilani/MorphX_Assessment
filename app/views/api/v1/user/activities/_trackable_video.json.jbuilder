# frozen_string_literal: true

json.logo_url             trackable.try(:logo_url)
json.poster_url           trackable.try(:poster_url)
json.price                trackable.try(:session) ? trackable.session.recorded_purchase_price : nil
json.purchased            current_ability.can?(:see_video_as_paid_member, trackable)
