# frozen_string_literal: true

envelope json, (@status || 200), (@user.pretty_errors if @user.errors.present?) do
  json.user do
    json.partial! 'user', user: @user
  end
  if @organization.present?
    json.current_organization do
      json.partial! 'api/v1/user/organizations/organization_short', organization: @organization

      json.default_location organization_default_user_path(@organization)
      json.membership_type  current_user.current_organization_membership_type
      json.has_active_subscription_or_split_revenue @organization.active_subscription_or_split_revenue?
    end
  end
  if @my_organization.present?
    json.my_organization do
      json.partial! 'api/v1/user/organizations/organization_short', organization: @my_organization
    end
  end
  json.organizations do
    json.array! @organizations do |org|
      json.partial! 'api/v1/user/organizations/organization_short', organization: org
    end
  end
  json.cache! ['app/views/api/v1/user/users/show/subscription_ability', current_user], expires_in: 1.day do
    if @organization.present? && @user == current_user
      json.subscription_ability do
        json.can_manage_blog current_ability.can?(:manage_blog_by_business_plan, @organization)
        json.can_manage_creators current_ability.can?(:manage_creators_by_business_plan, @organization)
        json.can_manage_admins current_ability.can?(:manage_admins_by_business_plan, @organization)
        json.can_manage_team current_ability.can?(:manage_team, @organization)
        json.can_access_multiroom current_ability.can?(:access_multiroom_by_business_plan, @organization)
        json.can_manage_multiroom current_ability.can?(:manage_multiroom_by_business_plan, @organization)
        json.can_access_products current_ability.can?(:access_products_by_business_plan, @organization)
        json.can_monetize_content current_ability.can?(:monetize_content_by_business_plan, @organization)
        json.can_manage_contacts_and_mailing current_ability.can?(:manage_contacts_and_mailing_by_business_plan, @organization)
        json.can_have_subscriptions current_user.has_approved_channels?
        json.can_create_interactive_stream current_ability.can?(:create_interactive_stream_feature, @organization)
        json.have_trial_service_subscription current_ability.can?(:have_trial_service_subscription, current_user)
      end
    end
  end
  if @user == current_user
    json.cache! ['app/views/api/v1/user/users/show/credentials_ability', current_user], expires_in: 1.day do
      json.credentials_ability do
        json.can_access_organization current_ability.can?(:access, @organization)
        json.can_invite_members current_ability.can?(:invite_members, @organization)
        json.can_remove_members current_ability.can?(:remove_members, @organization)
        json.can_edit_organization current_ability.can?(:edit, @organization)
        json.can_create_channel current_ability.can?(:create_channel, @organization)
        json.can_edit_channels current_ability.can?(:edit_channels, @organization)
        json.can_archive_channels current_ability.can?(:archive_channels, @organization)
        json.can_multiroom_config current_ability.can?(:multiroom_config, @organization)
        json.can_create_session current_ability.can?(:create_session, @organization)
        json.can_start_session current_ability.can?(:start_session, @organization)
        json.can_upload_recording current_ability.can?(:upload_recording, @organization)
        json.can_edit_recording current_ability.can?(:edit_recording, @organization)
        json.can_transcode_recording current_ability.can?(:transcode_recording, @organization)
        json.can_delete_recording current_ability.can?(:delete_recording, @organization)
        json.can_edit_replay current_ability.can?(:edit_replay, @organization)
        json.can_transcode_replay current_ability.can?(:transcode_replay, @organization)
        json.can_delete_replay current_ability.can?(:delete_replay, @organization)
        json.can_manage_documents current_ability.can?(:manage_documents, @organization)
        json.can_mail current_ability.can?(:mail, @organization)
        json.can_manage_roles current_ability.can?(:manage_roles, @organization)
        json.can_manage_creator current_ability.can?(:manage_creator, @organization)
        json.can_manage_enterprise_member current_ability.can?(:manage_enterprise_member, @organization)
        json.can_manage_admin current_ability.can?(:manage_admin, @organization)
        json.can_manage_superadmin current_ability.can?(:manage_superadmin, @organization)
        json.can_manage_team current_ability.can?(:manage_team, @organization)
        json.can_refund current_ability.can?(:refund, @organization)
        json.can_manage_payment_method current_ability.can?(:manage_payment_method, @organization)
        json.can_manage_channel_subscription current_ability.can?(:manage_channel_subscription, @organization)
        json.can_manage_business_plan current_ability.can?(:manage_business_plan, @organization)
        json.can_manage_product current_ability.can?(:manage_product, @organization)
        json.can_view_revenue_report current_ability.can?(:view_revenue_report, @organization)
        json.can_view_user_report current_ability.can?(:view_user_report, @organization)
        json.can_view_video_report current_ability.can?(:view_video_report, @organization)
        json.can_view_billing_report current_ability.can?(:view_billing_report, @organization)
        json.can_view_content current_ability.can?(:view_content, @organization)
        json.can_manage_blog_post current_ability.can?(:manage_blog_post, @organization)
        json.can_moderate_blog_post current_ability.can?(:moderate_blog_post, @organization)
        json.can_view_statistics current_ability.can?(:view_statistics, @organization)
        json.can_moderate_comments_and_reviews current_ability.can?(:moderate_comments_and_reviews, @organization)
        json.can_manage_booking current_ability.can?(:manage_booking, @organization)
        json.can_manage_polls current_ability.can?(:manage_polls, @organization)
      end
    end

    json.cache! ['has_subscriptions', current_user], expires_in: 1.day do
      json.has_subscription @has_service_subscription
      json.has_channel_subscriptions @channel_subscriptions.exists?(canceled_at: nil)
      json.has_channel_free_subscriptions @channel_free_subscriptions.exists?
    end
    json.has_payments current_user.payment_transactions.any?
  end
end
