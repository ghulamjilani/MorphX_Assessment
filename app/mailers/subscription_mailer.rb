# frozen_string_literal: true

class SubscriptionMailer < ApplicationMailer
  include Devise::Mailers::Helpers

  def channel_subscribed(stripe_db_subscription_id)
    stripe_subscription = StripeDb::Subscription.find(stripe_db_subscription_id)
    @user = stripe_subscription.user
    @plan = stripe_subscription.stripe_plan
    channel_subscription = stripe_subscription.channel_subscription
    @owner = channel_subscription.user
    @channel = channel_subscription.channel
    @direct_from_name = @channel.title

    @subject = 'New Subscription'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @owner,
      subject: @subject,
      sender: @user,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @owner.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def channel_subscription_receipt(log_transaction_id)
    @lt = LogTransaction.find(log_transaction_id)
    @user = @lt.user
    @plan = @lt.abstract_session
    @channel_subscription = @plan.channel_subscription
    @owner = @channel_subscription.user
    @channel = @channel_subscription.channel
    @payment_transaction = @lt.payment_transaction

    @subject = 'Thank you for purchasing subscription'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: @owner,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def gift_subscription(log_transaction_id)
    @lt = LogTransaction.find(log_transaction_id)
    @subscription = StripeDb::Subscription.find_by(stripe_id: @lt.data[:subscription_stripe_id])
    @user = @subscription.user
    @plan = @lt.abstract_session
    @channel_subscription = @plan.channel_subscription

    @owner = @subscription.customer_user
    @channel = @channel_subscription.channel
    @subject = 'Gift Subscription purchased'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @owner,
      subject: @subject,
      sender: @owner,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @owner.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def you_received_gift_subscription(log_transaction_id, user_id)
    @lt = LogTransaction.find(log_transaction_id)
    @subscription = @lt.subscription
    @user = User.find(user_id)
    @plan = @subscription.stripe_plan
    @channel_subscription = @plan.channel_subscription
    @owner = @subscription.customer_user
    @channel = @channel_subscription.channel
    if @channel
      @direct_from_name = @channel.title
      @follow_link_url = if @user.can_receive_abstract_session_invitation_without_invitation_token?
                           @channel.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))
                         else
                           accept_user_invitation_url(invitation_token: generate_user_invitation_token_and_return!,
                                                      return_to_after_connecting_account: @channel.absolute_path)
                         end
    end
    @subject = I18n.t('subscriptions.receive_gift_subject', user_name: @owner.public_display_name).strip
    @subject_with_name = I18n.t('subscriptions.receive_gift_subject', user_name: @owner.public_display_name)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: @owner,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @user.email,
         subject: @subject_with_name,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end
end
