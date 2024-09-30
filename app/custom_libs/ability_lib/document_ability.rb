# frozen_string_literal: true

module AbilityLib
  class DocumentAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      # anyone can access read-only info about visible documents in not archived channel
      can %i[index show], Document do |document|
        document.channel.organization.active_subscription_or_split_revenue? &&
          !document.channel.archived? && document.channel.show_documents? && !document.hidden?
      end

      # users who have any channel subscription can preview/download documents in not archived channel
      can :download, Document do |document|
        channel = document.channel
        (user.persisted? && (channel.organizer == user || user.has_channel_credential?(channel, :manage_documents))) ||
          (channel.organization.active_subscription_or_split_revenue? && !channel.archived? && channel.show_documents? && (
          !channel.subscription ||
            # free document show to all
            (document.free? && !document.only_subscription?) ||
            # purchased document show to user
            (user.persisted? && (document.document_members.exists?(user: user) ||
              # only subs show to subs
              (document.free? && document.only_subscription? && (::StripeDb::Subscription.joins(:channel_subscription).where(
                user: user, status: %i[active trialing], subscriptions: { channel_id: channel.id }
              ).present? || channel.free_subscriptions.in_action.with_features(:documents).exists?(user: user)))))
        ))
      end

      can :purchase, Document do |document|
        user.persisted? && !document.document_members.exists?(user: user)
      end

      # owner and people who have manage_documents credential can have full access to docs in not archived channel
      can %i[create update destroy manage], Document do |document|
        channel = document.channel
        channel.organization.active_subscription_or_split_revenue? && !channel.archived? &&
          user.has_channel_credential?(channel, :manage_documents)
      end
    end
  end
end
