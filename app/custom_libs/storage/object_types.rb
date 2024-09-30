# frozen_string_literal: true

module Storage
  module ObjectTypes
    LOCAL_ATTACHMENT = 'ActiveStorage::Attachment'
    S3_COLLECTION = 'Aws::S3::ObjectSummary::Collection'

    LOCAL = [LOCAL_ATTACHMENT].freeze
    S3 = [S3_COLLECTION].freeze
    ALL = [LOCAL, S3].flatten.freeze
  end
end
