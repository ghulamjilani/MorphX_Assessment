# frozen_string_literal: true

module AbilityLib
  class CommentAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      can :read, ::Comment do |_comment|
        true
      end

      can :comment, ::Comment do |_comment|
        lambda do
          return false unless user.persisted?

          true
        end.call
      end

      can :edit, ::Comment do |comment|
        user.persisted? && comment.user == user
      end

      can :destroy, ::Comment do |comment|
        can?(:edit, comment) || can?(:moderate, comment)
      end

      can :moderate, ::Comment do |comment|
        channel = comment.commentable.is_a?(Comment) ? comment.commentable.commentable.channel : comment.commentable.channel
        user.has_channel_credential?(channel, :moderate_comments_and_reviews)
      end
    end
  end
end
