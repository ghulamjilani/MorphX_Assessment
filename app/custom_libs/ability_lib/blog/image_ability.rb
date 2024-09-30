# frozen_string_literal: true

module AbilityLib
  module Blog
    class ImageAbility < AbilityLib::Blog::Base
      def service_admin_abilities
        @service_admin_abilities ||= {}
      end

      def load_permissions
        return unless user.persisted?

        can :update, ::Blog::Image do |image|
          Rails.cache.fetch("image_ability/update/#{image.cache_key}/#{user.cache_key}") do
            lambda do
              return true if image.organization.user == user

              if image.blog_post.present?
                return true if image.blog_post.user == user

                user.has_channel_credential?(image.blog_post.channel, %i[manage_blog_post moderate_blog_post])
              else
                user.has_organization_credential?(image.organization, %i[manage_blog_post moderate_blog_post])
              end
            end.call
          end
        end

        can :destroy, ::Blog::Image do |image|
          can?(:update, image)
        end
      end
    end
  end
end
