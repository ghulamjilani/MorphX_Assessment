# frozen_string_literal: true

namespace :blog do
  desc "Aggregate specific keys from notice group: bundle exec rake airbrake:aggregate[group_id,api_key,key_stack]\n bundle exec rake airbrake:aggregate[2967594393375034788,f7eadd26762ba11afa0e5f68677266b6bd59bad2,params/parameters/video_id]"
  task update_comments_count: [:environment] do
    Blog::Post.find_each(&:update_comments_count)
    Blog::Comment.find_each(&:update_comments_count)
  end
end
