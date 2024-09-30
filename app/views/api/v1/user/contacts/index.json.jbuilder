# frozen_string_literal: true

envelope json do
  json.array! @contacts do |contact|
    json.partial! 'contact', contact: contact
    if contact.contact_user
      json.contact_user do
        json.extract! contact.contact_user, :id, :public_display_name, :relative_path, :avatar_url
      end
    end
  end
end
