# frozen_string_literal: true

# There is no deploy:setup in Capistrano 3.0.0 - run it manually
namespace :deploy do
  desc 'Setup solr data dir'
  task :setup_solr_data_dir do
    on roles :app, :old_prods do
      within release_path do
        execute "mkdir -p #{shared_path}/solr/data"
      end
    end
  end

  desc 'Post-deploy configuration'
  task :post_deploy_configure do
    on roles :app, :old_prods do
      execute %(cd #{current_path} && bundle install && RAILS_ENV=#{fetch(:rails_env)} bundle exec rake robotstxt:write tmp:cache:clear )
      execute %(cd #{current_path} && bundle install && RAILS_ENV=#{fetch(:rails_env)} bundle exec rake assets:upload_additional )
    end
    on roles :main do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'install'
          execute :rake, 'robotstxt:write'
          execute :rake, 'tmp:cache:clear'
          execute :rake, 'assets:upload_additional'
        end
      end
    end
    on roles :main, :app, :old_prods do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'assets:clean'
        end
      end
    end
  end
  after 'deploy:finished', 'deploy:post_deploy_configure'
end
