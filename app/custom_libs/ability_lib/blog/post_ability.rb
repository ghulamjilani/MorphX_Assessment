# frozen_string_literal: true

module AbilityLib
  module Blog
    class PostAbility < AbilityLib::Blog::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          read: [::Blog::Post]
        }
      end

      def load_permissions
        can :share, ::Blog::Post do |blog_post|
          blog_post.status_published?
        end

        can :email_share, ::Blog::Post do |blog_post|
          user.persisted? && can?(:share, blog_post)
        end

        can :read, ::Blog::Post do |post|
          cache_key = "blog_post_ability/#{post.cache_key}/read/#{user.try(:cache_key)}/#{post.organization.try(:cache_key)}"
          Rails.cache.fetch(cache_key) do
            lambda do
              return false if Rails.application.credentials.global[:enterprise] &&
                              !user.has_channel_credential?(post.channel, :view_content)
              return false unless post.channel.organization.active_subscription_or_split_revenue?
              return true if post.status_published?

              user.has_channel_credential?(post.channel, %i[manage_blog_post moderate_blog_post])
            end.call
          end
        end

        can :edit, ::Blog::Post do |post|
          cache_key = "blog_post_ability/#{post.cache_key}/edit/#{user.try(:cache_key)}/#{post.organization.try(:cache_key)}"
          Rails.cache.fetch(cache_key) do
            lambda do
              return false unless post.channel.organization.active_subscription_or_split_revenue?
              return true if user.has_channel_credential?(post.channel, :moderate_blog_post)

              user == post.author && user.has_channel_credential?(post.channel, :manage_blog_post)
            end.call
          end
        end

        can :comment, ::Blog::Post do |post|
          user.persisted? && can?(:read, post)
        end

        can :track_view, ::Blog::Post do |post|
          can?(:read, post)
        end
      end
    end
  end
end
