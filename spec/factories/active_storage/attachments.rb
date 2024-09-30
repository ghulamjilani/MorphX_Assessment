# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_attachment, class: 'ActiveStorage::Attachment' do
    association :blob, factory: :active_storage_blob
    association :record, factory: :recording
    content_type {''}
    name { 'FCabKg==' }
  end
  factory :aa_stub_active_storage_attachments, parent: :active_storage_attachment
end
