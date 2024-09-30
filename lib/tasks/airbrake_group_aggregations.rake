# frozen_string_literal: true

namespace :airbrake do
  desc "Aggregate specific keys from notice group: bundle exec rake airbrake:aggregate[group_id,api_key,key_stack]\n bundle exec rake airbrake:aggregate[2967594393375034788,f7eadd26762ba11afa0e5f68677266b6bd59bad2,params/parameters/video_id]"
  task :aggregate, %i[group_id api_key key_stack] => [:environment] do |_task, args|
    ar_config = Rails.application.credentials.dig(:backend, :initialize, :airbrake)
    project_id = ar_config[:id]
    key = args[:api_key]

    path = "/api/v4/projects/#{project_id}/groups/#{args[:group_id]}/notices"
    client = Excon.new('https://api.airbrake.io', debug_response: true)
    stack = args[:key_stack].split('/')
    response = client.request(
      idempotent: true, retry_limit: 2, retry_interval: 5, expects: [200],
      method: :get, path: path, body: nil, query: { key: key }
    )
    notices = JSON.parse(response.body)['notices']
    result = notices.map { |n| n.dig(*stack).to_s }.reject(&:blank?)
    puts result.to_json
  end
end
