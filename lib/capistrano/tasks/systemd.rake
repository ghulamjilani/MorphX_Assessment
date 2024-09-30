# frozen_string_literal: true

require_relative '../../../config/deploy'

namespace :systemd do
  task :restart_sidekiq do
    on roles %i[main] do
      execute 'sudo systemctl restart sidekiq.service'
    end
  end

  task :start_sidekiq do
    on roles %i[main] do
      execute 'sudo systemctl start sidekiq.service'
    end
  end

  task :stop_sidekiq do
    on roles %i[main] do
      execute 'sudo systemctl stop sidekiq.service'
    end
  end

  after 'deploy:finished', 'systemd:restart_sidekiq'
end
