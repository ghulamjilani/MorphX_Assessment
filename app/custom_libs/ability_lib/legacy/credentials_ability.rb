# frozen_string_literal: true

module AbilityLib
  module Legacy
    class CredentialsAbility < AbilityLib::Legacy::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          access: [Organization]
        }
      end

      def initialize(user)
        super user

        can :access, Organization do |organization|
          lambda do
            return false unless user
            return true if organization.user == user

            user.organization_memberships_active.exists?(organization_id: organization)
          end.call
        end

        can :edit, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/edit/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_organization')
            end)
        end

        can :create_channel, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/create_channel/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'create_channel')
            end)
        end

        can :edit_channels, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/edit_channels/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'edit_channel')
            end)
        end

        can :multiroom_config, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/multiroom_config/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'multiroom_config')
            end)
        end

        can :edit, Channel do |channel|
          !channel.archived? && (channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/edit/#{channel.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: channel.organization.id }).exists?(code: 'edit_channel')
            end)
        end

        can :submit_for_review, Channel do |channel|
          channel.draft? && !channel.approved? && can?(:edit, channel)
        end

        can :list, Channel do |channel|
          !channel.listed? && channel.approved? && can?(:edit, channel)
        end

        can :unlist, Channel do |channel|
          raise ArgumentError unless channel.persisted?

          false
        end

        can :archive_channels, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/archive_channels/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'archive_channel')
            end)
        end

        can :archive, Channel do |channel|
          lambda do
            return false if channel.archived?

            user.has_channel_credential?(channel, :archive_channel)
          end.call
        end

        can :create_session, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/create_session/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'create_session')
            end)
        end

        can :create_session, User do
          can?(:create_session, user.current_organization)
        end

        can :create_session, Channel do |channel|
          channel.approved? && !channel.archived? && user.current_organization.present? &&
            (channel.organization.user == user || Rails.cache.fetch("credentials_ability/create_session/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :create_session }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end)
        end

        can :edit, Session do |session|
          pre_conditions = !session.finished? && !session.cancelled? && session.status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
          organization = session.channel.organization

          organization.user == user || (pre_conditions && can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/edit/session/#{session.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: session.channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :edit_session }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = session.channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(session.channel)
              end.call
            end)
        end

        can :cancel, Session do |session|
          pre_conditions = !session.finished? && !session.cancelled? && !session.started?
          organization = session.channel.organization

          organization.user == user || (pre_conditions && can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/cancel/session/#{session.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: session.channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :cancel_session }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = session.channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(session.channel)
              end.call
            end)
        end

        can :clone, Session do |session|
          organization = session.channel.organization
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/clone/session/#{session.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: session.channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :clone_session }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = session.channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(session.channel)
              end.call
            end)
        end

        can :invite_to_session, Session do |session|
          organization = session.channel.organization
          organization.user == user || session.presenter.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/invite_to_session/session/#{session.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'invite_to_session')
            end)
        end

        can :destroy_invitation, SessionInvitedImmersiveParticipantship do |participantship|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user && Rails.cache.fetch("ability/destroy_immersive_invitation/#{participantship.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.blank?

              can?(:invite_to_session, participantship.session) \
              && participantship.status != ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
            end.call
          end
        end

        can :destroy_invitation, SessionInvitedLivestreamParticipantship do |participantship|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user && Rails.cache.fetch("ability/destroy_livestream_invitation/#{participantship.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.blank?

              can?(:invite_to_session, participantship.session) \
              && participantship.status != ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
            end.call
          end
        end

        can :edit_ban_list, Session do |session|
          can?(:invite_to_session, session)
        end

        can :start, Session do |session|
          organization = session.channel.organization
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/start/session/#{session.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'start_session')
            end)
        end

        can :end, Session do |session|
          organization = session.channel.organization
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/end/session/#{session.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'end_session')
            end)
        end

        can :add_products, Session do |session|
          organization = session.channel.organization
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/add_products/session/#{session.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'add_products_to_session')
            end)
        end

        # Recordings
        can :upload_recording, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/upload_recording/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'create_recording')
            end)
        end

        can :upload_recording, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/upload_recording/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :create_recording }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :edit_recording, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/edit_recording/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'edit_recording')
            end)
        end

        can :edit_recording, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/edit_recording/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :edit_recording }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :edit, Recording do |recording|
          can?(:edit_recording, recording.channel)
        end

        can :transcode_recording, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/transcode_recording/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'transcode_recording')
            end)
        end

        can :transcode_recording, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/transcode_recording/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :transcode_recording }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :transcode, Recording do |recording|
          can?(:transcode_recording, recording.channel)
        end

        can :delete_recording, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/delete_recording/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'delete_recording')
            end)
        end

        can :delete_recording, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/delete_recording/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :delete_recording }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :delete, Recording do |recording|
          can?(:delete_recording, recording.channel)
        end

        # Video
        can :edit_replay, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/edit_replay/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'edit_replay')
            end)
        end

        can :edit_replay, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/edit_replay/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :edit_replay }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :edit, Video do |video|
          can?(:edit_replay, video.channel)
        end

        can :transcode_replay, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/transcode_replay/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'transcode_replay')
            end)
        end

        can :transcode_replay, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/transcode_replay/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :transcode_replay }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :transcode, Video do |video|
          can?(:transcode_replay, video.channel)
        end

        can :delete_replay, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/delete_replay/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'delete_replay')
            end)
        end

        can :delete_replay, Channel do |channel|
          channel.organization.user == user ||
            Rails.cache.fetch("credentials_ability/delete_replay/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :delete_replay }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end
        end

        can :delete, Video do |video|
          can?(:delete_replay, video.channel)
        end

        # Products
        can :manage_product, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_product/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_product')
            end)
        end

        # User Management
        can :manage_roles, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_roles/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_roles')
            end)
        end

        can :manage_admin, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_admin/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_admin')
            end)
        end

        can :manage_creator, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_creator/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_creator')
            end)
        end

        can :manage_enterprise_member, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_enterprise_member/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_enterprise_member')
            end)
        end

        can :manage_superadmin, Organization do |organization|
          organization.user == user
        end

        can :invite_members, Organization do |organization|
          can?(:manage_team, organization)
        end

        can :remove_members, Organization do |organization|
          can?(:manage_team, organization)
        end

        can :manage_team, Organization do |organization|
          (can?(:access, organization) &&
            can?(:manage_superadmin, organization)) ||
            can?(:manage_admin, organization) ||
            can?(:manage_creator, organization) ||
            can?(:manage_enterprise_member, organization)
        end

        can :view_statistics, Organization do |organization|
          can?(:view_video_report, organization) ||
            can?(:view_user_report, organization) ||
            can?(:view_revenue_report, organization) ||
            can?(:view_billing_report, organization)
        end

        can :read, OrganizationMembership do |organization_membership|
          lambda do
            return true if organization_membership.active?
            return false unless user
            return true if organization_membership.user == user
            return true if organization_membership.organization.user == user

            can?(:manage_team, organization_membership.organization)
          end.call
        end

        # Subscriptions
        can :manage_channel_subscription, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_channel_subscription/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_channel_subscription')
            end)
        end

        can :manage_business_plan, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_business_plan/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_business_plan')
            end)
        end

        # Payments
        can :refund, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/refund/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'refund')
            end)
        end

        can :manage_payment_method, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_payment_method/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_payment_method')
            end)
        end

        # Reports
        can :view_user_report, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/view_user_report/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'view_user_report')
            end)
        end

        can :view_video_report, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/view_video_report/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'view_video_report')
            end)
        end

        # Money Report
        can :view_billing_report, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/view_billing_report/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'view_billing_report')
            end)
        end

        can :view_revenue_report, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/view_revenue_report/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'view_revenue_report')
            end)
        end

        # View
        can :view_content, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/view_content/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'view_content')
            end)
        end

        # Blog
        can :manage_blog_post, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/manage_blog_post/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'manage_blog_post')
            end)
        end

        can :manage_blog_post, Channel do |channel|
          channel.organization.user == user || (can?(:access, channel.organization) &&
            Rails.cache.fetch("credentials_ability/manage_blog_post/channel/#{channel.cache_key}/#{user.cache_key}") do
              lambda do
                member = user.organization_memberships_active.find_by(organization_id: channel.organization_id)
                return false if member.blank?

                groups = member.groups.joins(:credentials).where(access_management_credentials: { code: :manage_blog_post }).pluck(:id)
                return false if groups.blank?

                channels = member.channels.where(access_management_groups_members: { access_management_group_id: groups }).approved.not_archived
                channels = channel.organization.channels if channels.empty? && !groups.empty?
                channels.include?(channel)
              end.call
            end)
        end

        can :moderate_blog_post, Organization do |organization|
          organization.user == user || (can?(:access, organization) &&
            Rails.cache.fetch("credentials_ability/moderate_blog_post/organization/#{organization.cache_key}/#{user.cache_key}") do
              user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'moderate_blog_post')
            end)
        end

        can :edit, ::Blog::Post do |post|
          (can?(:manage_blog_post,
                post.organization) && post.user == user) || can?(:moderate_blog_post, post.organization)
        end

        can :add_role, [::AccessManagement::Group, Organization] do |group, organization|
          Rails.cache.fetch("credentials_ability/add_role/user/#{user.id}/group/#{group.cache_key}/organization/#{organization.cache_key}") do
            lambda do
              return true if organization.user == user
              # only for owner
              return false if group.credentials.exists?(code: :manage_superadmin)
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Admin' }) && cannot?(
                :manage_admin, organization
              )
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Creator' }) && cannot?(
                :manage_creator, organization
              )
              return false if group.credentials.joins(:type).exists?(access_management_types: { name: 'Member' }) && cannot?(
                :manage_enterprise_member, organization
              )

              true
            end.call
          end
        end

        can :edit_roles, [User, Organization] do |member, _organization|
          member != user
        end
      end
    end
  end
end
