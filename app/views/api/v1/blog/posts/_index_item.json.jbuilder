# frozen_string_literal: true

json.post do
  json.partial! 'api/v1/public/blog/posts/post', post: post

  if current_ability.can?(:edit, post)
    json.can_edit  true
    json.user_id   post.user_id
  else
    json.can_edit  false
    json.user_id   post.hide_author ? nil : post.user_id
  end

  json.liked current_user.present? ? current_user.liked?(post) : false

  json.channel do
    json.partial! 'api/v1/public/channels/channel', model: post.channel
    json.can_create_post current_ability.can?(:manage_blog_post, post.channel)
  end
  json.user do
    json.partial! 'api/v1/public/users/user_short', model: post.user
  end
  json.link_previews do
    json.array! post.link_previews do |link_preview|
      if link_preview.present?
        json.link_preview do
          json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: link_preview
        end
      end
    end
  end
  if post.featured_link_preview.present?
    json.featured_link_preview do
      json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: post.featured_link_preview
    end
  end
end
