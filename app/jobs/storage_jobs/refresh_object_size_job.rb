# frozen_string_literal: true

module StorageJobs
  class RefreshObjectSizeJob < ApplicationJob
    def perform(storage_record_id)
      storage_record = Storage::Record.find(storage_record_id)
      storage_record.manager.refresh_object_size
    end
  end
end
