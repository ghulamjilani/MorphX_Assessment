# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::Blob.include(ModelConcerns::ActiveStorage::Blob::Extensions)
end
