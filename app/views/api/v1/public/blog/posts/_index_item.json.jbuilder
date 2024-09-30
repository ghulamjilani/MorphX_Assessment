# frozen_string_literal: true

json.post do
  json.partial! 'api/v1/public/blog/posts/post_short', post: post

  json.channel do
    json.extract! post.channel, :id, :title, :relative_path, :logo_url
  end

  json.user do
    if post.hide_author?
      json.partial! 'api/v1/public/users/user_short', model: nil
    else
      json.partial! 'api/v1/public/users/user_short', model: post.user
    end
  end

  json.organization do
    json.partial! '/api/v1/public/organizations/organization_short', model: post.organization
  end
end
