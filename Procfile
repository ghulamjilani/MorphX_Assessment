rails: RAILS_ENV=development bundle exec puma -C config/puma/development.rb
log: tail -f log/development.log
webpack: ./bin/webpacker --watch --progress
sidekiq: RAILS_ENV=development bundle exec sidekiq