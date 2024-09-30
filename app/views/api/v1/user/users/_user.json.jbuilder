# frozen_string_literal: true

json.id                   user.id
json.first_name           user.first_name
json.last_name            user.last_name
json.email                user.email
json.birthdate            user.birthdate
json.gender               user.gender
json.avatar_url           user.avatar_url
json.slug                 user.slug
json.display_name         user.display_name
json.public_display_name  user.public_display_name
json.confirmed_at         user.confirmed_at
json.updated_at           user.updated_at.utc.to_fs(:rfc3339)
json.created_at           user.created_at.utc.to_fs(:rfc3339)
json.url                  user.absolute_path
json.role                 user.role
json.current_role         user.current_role
json.presenter_id         user.presenter&.id
json.platform_role        user.platform_role
json.country              user.user_account&.country

json.can_use_debug_area    user.can_use_debug_area
json.can_create_session    current_ability.can?(:create_session, user.current_organization)
json.can_become_a_creator  current_ability.can?(:become_a_creator, user)
json.become_creator_status user.presenter&.last_seen_become_presenter_step
if current_ability.can?(:become_a_creator, user)
  json.become_creator_link  user.become_creator_link
  json.become_creator_title user.become_creator_title
end

json.remember_created_at    user.remember_created_at
json.sign_in_count          user.sign_in_count
json.current_sign_in_at     user.current_sign_in_at
json.last_sign_in_at        user.last_sign_in_at
json.current_sign_in_ip     user.current_sign_in_ip
json.last_sign_in_ip        user.last_sign_in_ip
json.confirmed_at           user.confirmed_at
json.confirmation_sent_at   user.confirmation_sent_at
json.deleted                user.deleted
json.invitation_created_at  user.invitation_created_at
json.invitation_sent_at     user.invitation_sent_at
json.invitation_accepted_at user.invitation_accepted_at
json.invitation_limit       user.invitation_limit
json.invited_by_type        user.invited_by_type
json.invited_by_id          user.invited_by_id
json.unconfirmed_email      user.unconfirmed_email
json.braintree_customer_id  user.braintree_customer_id
json.facebook_friends       user.facebook_friends
json.time_format            user.time_format
json.am_format              user.time_format == User::TimeFormats::HOUR_12
json.timezone               user.timezone
json.manually_set_timezone  user.manually_set_timezone
json.dropbox_token          user.dropbox_token
json.profit_margin_percent  user.current_organization_revenue_percent
json.shares_count           user.shares_count
json.slug                   user.slug
json.currency               user.currency
json.short_url              user.short_url
json.fake                   user.fake
json.show_on_home           user.show_on_home
json.affiliate_signature    user.affiliate_signature
json.custom_slug            user.custom_slug
json.referral_short_url     user.referral_short_url
json.promo_start            user.promo_start
json.promo_end              user.promo_end
json.promo_weight           user.promo_weight
json.language               user.language
json.can_use_barcode_area   user.can_use_barcode_area
json.can_use_wizard         user.can_use_wizard
json.can_buy_subscription   user.can_buy_subscription
json.ffmpegservice_transcode        user.ffmpegservice_transcode
json.start_creating         !user.presenter&.channel_invited_presenterships&.exists?(status: 'accepted') && !user.organization_memberships_active.exists?
json.has_memberships        user.organization_memberships_active.exists?

json.public_display_name_source                          user.public_display_name_source
json.referral_participant_fee_in_percent                 user.referral_participant_fee_in_percent
json.can_create_sessions_with_max_duration               user.can_create_sessions_with_max_duration
json.can_create_free_private_sessions_without_permission user.can_create_free_private_sessions_without_permission
json.can_publish_n_free_sessions_without_admin_approval  user.can_publish_n_free_sessions_without_admin_approval
json.free_private_sessions_without_admin_approval_left_count user.free_private_interactive_without_admin_approval_left_count
json.overriden_minimum_live_session_cost                 user.overriden_minimum_live_session_cost
json.welcome_new_user_email_is_sent                      user.welcome_new_user_email_is_sent

json.unread_messages_count                               user.unread_messages_count
json.new_notifications_count                             user.new_notifications_count
json.blocking_notifications                              user.blocking_notifications

# for Victor until he stop to use old api
if params[:controller].include?('api/v1/auth/')
  json.authentication_token user.authentication_token
end
