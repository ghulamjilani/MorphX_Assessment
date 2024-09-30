# frozen_string_literal: true

json.contact do
  json.id       @contact.id
  json.name     @contact.name
  json.email    @contact.email
  json.status   @contact.status
end
