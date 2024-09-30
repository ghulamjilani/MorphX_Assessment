# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_blob, class: 'ActiveStorage::Blob' do
    filename { 'sss' }
    byte_size { 0 }
    checksum { 'FCabtk/ZnUGc9XFNnLu/Kg==' }
    content_type {''}
  end

  factory :active_storage_blob_pdf, parent: :active_storage_blob do
    after(:build) do |model|
      model.upload(File.open(Rails.root.join('spec', 'fixtures', 'active_storage', 'test.pdf')))
    end
  end

  factory :aa_stub_active_storage_blobs, parent: :active_storage_blob
end
