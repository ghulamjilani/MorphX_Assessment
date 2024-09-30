# frozen_string_literal: true

module AbilityLib
  module Blog
    class CommentAbility < AbilityLib::Blog::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          read: [::Blog::Comment]
        }
      end

      def load_permissions
        can :read, ::Blog::Comment do |comment|
          lambda do
            post = comment.post
            return false if Rails.application.credentials.global[:enterprise] && !user.has_channel_credential?(
              post.channel, :view_content
            )
            return true if post.status_published?
            return false unless user.persisted?
            return true if comment.user == user
            return true if post.user == user

            user.has_channel_credential?(post.channel, %i[manage_blog_post moderate_blog_post])
          end.call
        end

        return unless user.persisted?

        can :edit, ::Blog::Comment do |comment|
          comment.user == user
        end

        can :comment, ::Blog::Comment do |comment|
          can?(:read, comment)
        end

        can :destroy, ::Blog::Comment do |comment|
          lambda do
            return true if can?(:edit, comment)

            post = comment.post
            return true if post.user == user

            user.has_channel_credential?(post.channel, %i[manage_blog_post moderate_blog_post])
          end.call
        end
      end
    end
  end
end
