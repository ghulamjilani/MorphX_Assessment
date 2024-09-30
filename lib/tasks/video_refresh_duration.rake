# frozen_string_literal: true

namespace :video do
  task :refresh_duration, [:ids] => :environment do |_task, args|
    videos = Video.where(status: :done).where.not(hls_main: nil)
    if (args[:ids]).present?
      ids = args[:ids].split(',')
      videos = videos.where(id: ids)
    end

    videos.pluck(:id).each { |id| VideoJobs::RefreshDuration.perform_async(id) }
  end
end
