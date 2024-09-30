# frozen_string_literal: true

envelope json do
  json.post do
    json.partial! 'post', post: @post
    json.channel do
      json.partial! 'api/v1/public/channels/channel', model: @post.channel
      json.can_create_post current_ability.can?(:manage_blog_post, @post.channel)
    end
    json.user do
      json.partial! 'api/v1/public/users/user_short', model: @post.user
    end
    json.link_previews do
      json.array! @post.link_previews do |link_preview|
        if link_preview.present?
          json.link_preview do
            json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: link_preview
          end
        end
      end
    end
    if @post.featured_link_preview.present?
      json.featured_link_preview do
        json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: @post.featured_link_preview
      end
    end
    json.images do
      json.array! @post.blog_images do |image|
        if image.present?
          json.image do
            json.partial! 'api/v1/blog/images/image', image: image
          end
        end
      end
    end
  end
end
