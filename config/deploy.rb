# frozen_string_literal: true

set :application, 'Portal'

set :format, :pretty
set :log_level, :debug
set :pty, true

set :repo_url, 'git@github.com:PrincipleSoft/Portal.git'
set :rvm_ruby_version, '3.1.1@morphx'
set :user, 'deployer'
set :deploy_to, '/home/deployer/Portal'
set :pids_folder, '/home/deployer/pids'
set :linked_files, %w[config/database.yml .env config/firebase-production.json]

set :linked_dirs, %w[log tmp public/system]

set :keep_releases, 2
set :keep_assets, 4
set :rvm_roles, %i[app web main]
set :sidekiq_roles, %i[app main]

set :solr, false

namespace :deploy do
  after :publishing, :restart
  # after :finished, 'airbrake:deploy' it will close unresolved issues
end
