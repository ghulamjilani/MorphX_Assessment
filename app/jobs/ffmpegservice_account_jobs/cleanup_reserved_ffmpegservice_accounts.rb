# frozen_string_literal: true

class FfmpegserviceAccountJobs::CleanupReservedFfmpegserviceAccounts < ApplicationJob
  def perform(*_args)
    FfmpegserviceAccount.where.not(reserved_by_id: nil).where('updated_at < ?', 30.minutes.ago).update_all(
      reserved_by_id: nil, reserved_by_type: nil
    )
  end
end
