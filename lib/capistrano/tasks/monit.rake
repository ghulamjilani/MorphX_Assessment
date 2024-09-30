# frozen_string_literal: true

require_relative '../../../config/deploy'

namespace :monit do
  task :restart do
    on roles %i[main workers] do
      execute 'sudo monit restart puma_portal'
    end
  end

  after 'deploy:finished', 'monit:restart'
end

namespace :monit do
  desc 'Monit:reload config'
  task :reload do
    on roles %i[main workers] do
      execute 'sudo monit reload'
    end
  end
  desc 'Start Puma'
  task :start_puma do
    on roles %i[main workers] do
      execute 'sudo monit start puma_portal'
    end
  end
  desc 'Stop Puma'
  task :stop_puma do
    on roles %i[main workers] do
      execute 'sudo monit stop puma_portal'
    end
  end
  desc 'Start Sidekiq'
  task :start_sidekiq do
    on roles %i[main workers] do
      execute 'sudo monit start sidekiq_Portal_production_0'
    end
  end
  desc 'Stop Sidekiq'
  task :stop_sidekiq do
    on roles %i[main workers] do
      execute 'sudo monit stop sidekiq_Portal_production_0'
    end
  end
end
