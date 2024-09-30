# frozen_string_literal: true

json.logo_url             trackable.try(:logo_url)
json.poster_url           trackable.try(:poster_url)
json.price                trackable.try(:livestream_purchase_price) ? trackable.livestream_purchase_price : nil
json.purchased            trackable.try(:session) ? current_ability.can?(:live_opt_out, trackable.session) : false
