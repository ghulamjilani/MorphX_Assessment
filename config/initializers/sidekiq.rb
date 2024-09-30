# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['RESQUE_REDIS_URL'] }
  # Sidekiq::Cron::Job.load_from_hash YAML.load_file("#{Rails.root}/config/resque_schedule.yml") #it don't run the jobs

  Sidekiq::Cron::Job.create(name: 'video_title_and_url',                        cron: '0 */5 * * *',
                            class: 'UpdateVideoTitleAndUrl')
  Sidekiq::Cron::Job.create(name: 'log_transactions_printability',              cron: '0 */12 * * *',
                            class: 'CheckLogTransactionsForPrintability')
  Sidekiq::Cron::Job.create(name: 'refresh_exchange_rates',                     cron: '0 */6 * * *',
                            class: 'ExchangeRatesFetcher')

  Sidekiq::Cron::Job.create(name: 'Search for videos with outdated solr index', cron: '0 */5 * * * *',
                            class: 'VideoOutdatedIndexSearch')
  Sidekiq::Cron::Job.create(name: 'cleanup_video_notifications', cron: '0 0 * * *',
                            class: 'VideoJobs::CleanupNotificationsJob')
  Sidekiq::Cron::Job.create(name: 'cleanup reserved wa every 15m', cron: '*/15 * * * *',
                            class: 'FfmpegserviceAccountJobs::CleanupReservedFfmpegserviceAccounts')
  Sidekiq::Cron::Job.create(name: 'api_jobs_diagnostic', cron: '0 * * * *', class: 'Diagnostic::SidekiqEnqueue')
  Sidekiq::Cron::Job.create(name: 'stream_jobs_diagnostic', cron: '*/4 * * * *', class: 'Diagnostic::StreamJob')
  Sidekiq::Cron::Job.create(name: 'payout_job', cron: '0 0 5,20 * *', class: 'PayoutJob')
  Sidekiq::Cron::Job.create(name: 'This job ping watchers count every 1m', cron: '*/1 * * * *',
                            class: 'SessionJobs::WatchersCounterJob')

  # System jobs
  Sidekiq::Cron::Job.create(name: 'Broadcast server time every 30 seconds', cron: '*/30 * * * * *', class: 'SystemJobs::ServerTimeJob')

  Sidekiq::Cron::Job.create(name: 'Check trial subscription end every 5 min', cron: '*/5 * * * * *', class: 'ServiceSubscriptionJobs::TrialEndCheckJob')

  if Rails.env.qa? || Rails.env.production?
    Sidekiq::Cron::Job.create(name: 'create_reports', cron: '30 1 * * *', class: 'ReportJobs::Schedules')

    Sidekiq::Cron::Job.create(name: 'find_non_correct_records', cron: '*/5 * * * *', class: 'FindNonCorrectRecords')

    # Videos jobs
    Sidekiq::Cron::Job.create(name: 'Create Videos', cron: '*/5 * * * *', class: 'VideoJobs::Create')
    Sidekiq::Cron::Job.create(name: 'Upload Videos', cron: '*/5 * * * *', class: 'VideoJobs::Upload')
    Sidekiq::Cron::Job.create(name: 'Transcode Videos', cron: '*/6 * * * *', class: 'VideoJobs::TranscodeSchedulerJob')
    Sidekiq::Cron::Job.create(name: 'Cleanup non_transcoded Videos', cron: '0 0 * * *', class: 'VideoJobs::Cleanup')
    Sidekiq::Cron::Job.create(name: 'Delete marked_to_destroy Videos', cron: '20 0 * * 6', class: 'VideoJobs::Delete')
    Sidekiq::Cron::Job.create(name: 'Check videos hls_main', cron: '0 12 * * *', class: 'VideoJobs::FindBrokenVideos')
    Sidekiq::Cron::Job.create(name: 'Check availability of original files of downloaded videos', cron: '*/4 * * * *', class: 'VideoJobs::VerifyOriginalJob')
    Sidekiq::Cron::Job.create(name: 'Check availability of transcoded videos', cron: '*/3 * * * *', class: 'VideoJobs::VerifyTranscodedJob')
    Sidekiq::Cron::Job.create(name: 'Monitor missing videos for sessions with enabled recording', cron: '0 * * * *', class: 'VideoJobs::CreateMonitorJob')

    # Recordings jobs
    Sidekiq::Cron::Job.create(name: 'Delete Recordings', cron: '*/5 * * * *', class: 'RecordingJobs::Delete')
    Sidekiq::Cron::Job.create(name: 'Transcode Recordings', cron: '*/6 * * * *', class: 'RecordingJobs::TranscodeSchedulerJob')
    Sidekiq::Cron::Job.create(name: 'Chech recordings hls_main', cron: '0 12 * * *',
                              class: 'RecordingJobs::FindBrokenRecordings')
    Sidekiq::Cron::Job.create(name: 'Check availability of transcoded recordings', cron: '*/4 * * * *', class: 'RecordingJobs::VerifyTranscodedJob')

    Sidekiq::Cron::Job.create(name: 'Ping transcode progress every 1m', cron: '*/1 * * * *', class: 'TranscodableJobs::PingStatusesJob')

    # Webrtcservice jobs
    Sidekiq::Cron::Job.create(name: 'Create Compositions', cron: '*/5 * * * *',
                              class: 'Webrtcservice::VideoJobs::CreateCompositionsJob')
    Sidekiq::Cron::Job.create(name: 'Save completed webrtcservice videos', cron: '*/5 * * * *',
                              class: 'Webrtcservice::VideoJobs::CreateVideosJob')
    # Sidekiq::Cron::Job.create(name: 'Delete completed webrtcservice recordings', cron: '*/5 * * * *', class: Webrtcservice::Video::DeleteCompletedRecordingsJob)

    # FfmpegserviceAccount Jobs
    Sidekiq::Cron::Job.create(name: 'Create pull of unassigned ffmpegservice accounts', cron: '*/75 * * * *', class: 'FfmpegserviceAccountJobs::Generate')
    Sidekiq::Cron::Job.create(name: 'Sync ffmpegservice accounts', cron: '*/60 * * * *', class: 'FfmpegserviceAccountJobs::Sync')
    Sidekiq::Cron::Job.create(name: 'Rename ffmpegservice accounts', cron: '*/20 * * * *', class: 'FfmpegserviceAccountJobs::RenameJob')
    Sidekiq::Cron::Job.create(name: 'FfmpegserviceAccountJobs::AuthenticateJob', cron: '*/20 * * * *', class: 'FfmpegserviceAccountJobs::AuthenticateJob')

    Sidekiq::Cron::Job.create(name: 'Recalculate views counts', cron: '0 12 * * 7',
                              class: 'ViewableJobs::RecalculateViewsJob')
  end

  Sidekiq::Cron::Job.create(name: 'Count new views, increment views counts every 30s', cron: '*/30 * * * * *',
                            class: 'ViewableJobs::IncrementAccumulatedViewsCountJob')

  Sidekiq::Cron::Job.create(name: 'stop_stuck_streams', cron: '*/10 * * * *', class: 'ApiJobs::StopStuckStreams')
  Sidekiq::Cron::Job.create(name: 'Cleanup not attached blog images', cron: '0 0 * * *',
                            class: 'BlogJobs::ClearImagesJob')

  if Rails.env.development?
    Sidekiq::Cron::Job.create(name: 'generate_seed_data', cron: '0 22 * * *', class: 'GenerateSeedData')
  end

  if Rails.env.qa? || Rails.env.development?
    Sidekiq::Cron::Job.create(name: 'delete_old_sessions', cron: '0 23 * * *', class: 'DeleteOldRecords')
  end
  Sidekiq::Cron::Job.create(name: 'Check Grace Subscriptions', cron: '0 * * * *',
                            class: 'ServiceSubscriptionJobs::GraceCheckJob')
  Sidekiq::Cron::Job.create(name: 'Check Suspended Subscriptions', cron: '0 * * * *',
                            class: 'ServiceSubscriptionJobs::SuspendedCheckJob')
  Sidekiq::Cron::Job.create(name: 'Check Trial Suspended Subscriptions', cron: '0 * * * *',
                            class: 'ServiceSubscriptionJobs::TrialSuspendedCheckJob')
  Sidekiq::Cron::Job.create(name: 'Send email for Suspended Subscriptions', cron: '0 1 * * *',
                            class: 'ServiceSubscriptionJobs::SuspendedMailerJob')
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['RESQUE_REDIS_URL'] }
end

Sidekiq.strict_args!(false)
