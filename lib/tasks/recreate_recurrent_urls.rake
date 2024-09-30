# frozen_string_literal: true

namespace :sessions do
  desc 'Recreate urls for previosly created recurrent sessions with the same short urls'
  task recreate_recurring_urls: [:environment] do |_task, _args|
    sessions_dup_url = ActiveRecord::Base.connection.execute('SELECT id, short_url FROM sessions where short_url IN (SELECT short_url FROM sessions GROUP BY sessions.short_url HAVING COUNT(sessions.*) > 1)').values
    sessions_groups = {}
    sessions_dup_url.each do |session|
      sessions_groups[session[1]] ||= []
      sessions_groups[session[1]] << session[0]
    end
    sessions_groups.each do |short_url, group|
      sessions_groups[short_url] = group.sort[1..]
    end
    ids_to_refresh = sessions_groups.values.flatten
    Session.where(id: ids_to_refresh).find_each(&:recreate_short_urls)
  end
end
