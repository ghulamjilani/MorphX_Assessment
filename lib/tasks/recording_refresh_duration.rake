# frozen_string_literal: true

namespace :recording do
  task :refresh_duration, [:ids] => :environment do |_task, args|
    recordings = Recording.where(status: :done).where.not(hls_main: nil)
    if (args[:ids]).present?
      ids = args[:ids].split(',')
      recordings = recordings.where(id: ids)
    end

    recordings.pluck(:id).each { |id| RecordingJobs::RefreshDuration.perform_async(id) }
  end
end
