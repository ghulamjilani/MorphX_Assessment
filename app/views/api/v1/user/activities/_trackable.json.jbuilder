# frozen_string_literal: true

json.id                   trackable.id
json.type                 trackable.class.name
json.name                 trackable.always_present_title
json.short_url            trackable.try :short_url
json.relative_path        trackable.try :relative_path
json.following            current_user.following?(trackable)
json.private              trackable.try(:private)

# json.logo_url             trackable.try(:logo_url)
# json.poster_url           trackable.try(:poster_url)
# json.price                trackable.try(:price)
# json.purchased            trackable.try(:purchased)
