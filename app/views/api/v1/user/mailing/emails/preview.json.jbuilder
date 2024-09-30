# frozen_string_literal: true

json.email do
  json.partial! 'email', email: @email
end

json.template do
  json.partial! 'api/v1/user/mailing/templates/template', template: @template
end

json.contacts do
  json.array! @contacts do |contact|
    json.contact do
      json.partial! 'api/v1/user/contacts/contact', contact: contact
    end
  end
end
