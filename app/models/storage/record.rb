# frozen_string_literal: true
module Storage
  class Record < Storage::ApplicationRecord
    include ModelConcerns::Shared::ChangesStorageUsage

    belongs_to :model, polymorphic: true, optional: false
    belongs_to :blob, class_name: 'ActiveStorage::Blob', optional: true
    belongs_to :organization, class_name: 'Organization',
                              foreign_key: :organization_uuid,
                              primary_key: :uuid,
                              inverse_of: :storage_records,
                              optional: false

    before_validation :set_organization, unless: :organization_uuid?
    before_validation :set_blob_id, unless: :blob_id?

    validates :organization_uuid, presence: true
    validates :object_id, :object_type, :relation_type, presence: true
    validates :object_type, inclusion: { in: ::Storage::ObjectTypes::ALL }
    validates :s3_bucket_name, presence: true, if: ->(obj) { ::Storage::ObjectTypes::S3.include?(obj.object_type) }

    after_create :refresh_object_size
    after_update :increment_usage, if: :saved_change_to_byte_size?
    after_destroy :decrement_usage
    after_destroy_commit :remove_object

    delegate :id, to: :organization, prefix: true, allow_nil: false
    delegate :remove_object, :refresh_record, to: :manager

    def refresh_object_size
      StorageJobs::RefreshObjectSizeJob.perform_async(id)
    end

    def object
      raise ArgumentError if ::Storage::ObjectTypes::LOCAL.exclude?(object_type)

      object_type.constantize.find(object_id)
    end

    def blob_exists?
      blob_id && ActiveStorage::Blob.exists?(id: blob_id)
    end

    def manager
      @manager ||= Storage::RecordManagerFactory.create(self)
    end

    private

    def increment_usage
      byte_size_diff = byte_size.to_i - byte_size_previously_was.to_i
      change_storage_usage!(byte_size_diff, { action_name: relation_type })
    end

    def decrement_usage
      return if organization.blank?

      change_storage_usage!(-byte_size, { action_name: "#{relation_type} destroy" })
    end

    def set_organization
      self.organization_uuid = model.organization.uuid
    end

    def set_blob_id
      return if ::Storage::ObjectTypes::LOCAL.exclude?(object_type)

      self.blob_id = object.blob_id
    end
  end
end
