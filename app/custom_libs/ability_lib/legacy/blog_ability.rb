# frozen_string_literal: true

module AbilityLib
  module Legacy
    class BlogAbility < AbilityLib::Legacy::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          read: [::Blog::Post, ::Blog::Comment]
        }
      end

      def initialize(user)
        super user

        can :edit, ::Blog::Post do |post|
          user.present? && Rails.cache.fetch("ability/edit_post/#{post.cache_key}/#{user.try(:cache_key)}") do
            ::Blog::Post.editable_by_user(user).exists?(id: post.id)
          end
        end

        can :edit, ::Blog::Comment do |comment|
          user.present? && comment.user == user
        end

        can :read, ::Blog::Post do |post|
          can?(:edit, post) \
          || ::Blog::Post.visible_for_user(user).exists?(id: post.id)
        end

        can :read, ::Blog::Comment do |comment|
          can?(:read, comment.post) || can?(:edit, comment)
        end

        can :create_post, Channel do |channel|
          pre_conditions = user.present? && !channel.archived? && channel.approved?

          pre_conditions && Rails.cache.fetch("ability/create_post/#{channel.cache_key}/#{user.try(:cache_key)}") do
            channel.organizer == user ||
              channel.users.exists?(users: { id: user.id }) ||
              (channel.organization.present? && channel.organization.organization_memberships_active.exists?(
                role: ['administrator'], user_id: user.id
              ))
          end
        end

        can :comment, ::Blog::Post do |post|
          user.present? && can?(:read, post)
        end

        can :comment, ::Blog::Comment do |comment|
          user.present? && can?(:read, comment)
        end

        can :destroy, ::Blog::Comment do |comment|
          can?(:edit, comment) || can?(:edit, comment.post)
        end

        can :create_blog_image, Organization do |organization|
          user.present? && Rails.cache.fetch("ability/create_blog_image/#{organization.cache_key}/#{user.try(:cache_key)}") do
            organization.user == user ||
              organization.presenter_users.where(id: user.id) ||
              organization.organization_memberships_active.exists?(role: ['administrator'], user_id: user.id)
          end
        end

        can :update, ::Blog::Image do |image|
          user.present? && Rails.cache.fetch("ability/update_blog_image/#{image.cache_key}/#{user.try(:cache_key)}") do
            image.organization.user == user ||
              (image.blog_post.nil? && can?(:create_blog_image, image.organization)) ||
              (image.blog_post.present? && can?(:edit, image.blog_post))
          end
        end

        can :destroy, ::Blog::Image do |image|
          user.present? && can?(:update, image)
        end
      end
    end
  end
end
