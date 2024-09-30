# frozen_string_literal: true
FactoryBot.define do
  factory :storage_record_attachment, class: 'Storage::Record' do
    model { create(:recording) }
    relation_type { :file }
    object_type { model.file.attachment.class.name }

    after(:build) do |storage_record|
      storage_record.object_id = storage_record.model.file.attachment.id
    end
  end

  factory :storage_record_s3_collection, class: 'Storage::Record' do
    model { create(:video) }
    relation_type { :file }
    object_type { 'Aws::S3::ObjectSummary::Collection' }
    s3_bucket_name { 'test' }
    byte_size { rand(666) }

    after(:build) do |storage_record|
      storage_record.object_id = storage_record.model.s3_path.gsub(%r{^/}, '').concat("/#{SecureRandom.hex(16)}.mp4")
    end
  end

  factory :aa_stub_storage_records, parent: :storage_record_attachment
end
