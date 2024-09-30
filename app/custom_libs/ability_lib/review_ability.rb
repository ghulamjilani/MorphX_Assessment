# frozen_string_literal: true

module AbilityLib
  class ReviewAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      can :edit, ::Review do |review|
        user.persisted? && review.user == user
      end

      can :moderate, ::Review do |review|
        lambda do
          return false unless user.persisted?

          user.has_channel_credential?(review.commentable.channel, :moderate_comments_and_reviews)
        end.call
      end

      can :read_technical_experience_comment, ::Review do |review|
        lambda do
          return false unless user.persisted?
          return true if user.service_admin? || user.platform_owner? || user == review.user

          user.has_channel_credential?(review.commentable.channel, :moderate_comments_and_reviews)
        end.call
      end
    end
  end
end
