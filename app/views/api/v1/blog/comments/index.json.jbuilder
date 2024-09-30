# frozen_string_literal: true

envelope json do
  json.comments do
    json.array! @comments do |comment|
      json.comment do
        json.partial! 'comment', comment: comment
        json.user do
          json.partial! 'api/v1/public/users/user_short', model: comment.user
        end
        json.link_previews do
          json.array! comment.link_previews do |link_preview|
            if link_preview.present?
              json.link_preview do
                json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: link_preview
              end
            end
          end
        end
        if comment.featured_link_preview.present?
          json.featured_link_preview do
            json.partial! 'api/v1/blog/link_previews/link_preview', link_preview: comment.featured_link_preview
          end
        end
      end
    end
  end
end
