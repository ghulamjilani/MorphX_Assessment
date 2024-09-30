# frozen_string_literal: true

ResqueApi = Resque.clone
ResqueApi.redis = Redis.new(url: ENV['RESQUE_API_REDIS_URL'])
