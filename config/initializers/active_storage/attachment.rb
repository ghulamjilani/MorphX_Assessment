# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::Attachment.include(ModelConcerns::ActiveStorage::Attachment::Extensions)
end
