# frozen_string_literal: true

Rails.application.config.to_prepare do
  Sender::FirebaseLib.config = File.read("#{Rails.root}/config/firebase-#{Rails.env}.json")
end
