# frozen_string_literal: true

class ServiceSubscriptionsMailer < ApplicationMailer
  include Devise::Mailers::Helpers
  layout 'email'

  def receipt(log_transaction_id)
    @lt = LogTransaction.find(log_transaction_id)
    @user = @lt.user
    @plan = @lt.abstract_session
    @payment_transaction = @lt.payment_transaction

    charge = Stripe::Charge.retrieve(@payment_transaction.pid)
    @invoice = Stripe::Invoice.retrieve(charge.invoice) if charge.invoice
    @discount = @invoice&.discount

    @subject = I18n.t('mailers.service_subscriptions_mailer.receipt.subject')
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  # 1 Trial started
  def trial_started(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(Welcome to #{Rails.application.credentials.global[:service_name]}! Your Trial has started!)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 2 Trail is Cancelled by Owner
  def trial_ended(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(Your #{Rails.application.credentials.global[:service_name]} Trial has been cancelled.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 2 Trail will end soon
  def trial_will_end_soon(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(Your #{Rails.application.credentials.global[:service_name]} Trial finishes in 1 day.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  def activated(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(Welcome to #{Rails.application.credentials.global[:service_name]}! Your Business Plan is activated!)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  def cancellation_requested(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(#{Rails.application.credentials.global[:service_name]} Business Plan will be cancelled.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 23 Subscription Cancellation by Owner - end of service
  def canceled(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = %(Your #{Rails.application.credentials.global[:service_name]} Business Plan has been cancelled.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 7 Trial time is finished - subscription wasn't activated
  def trial_finished_payment_failed(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @suspended_days = @subscription.feature_parameters.by_code(:trial_suspended_days).first&.value.to_i || 3

    @subject = %(#{Rails.application.credentials.global[:service_name]} Business Plan activation failed: please check your payment method.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 8 Trial time is finished - subscription wasn't activated within {TRIAL_SUSPENDED_DAYS} days, (content removal)
  def trial_suspended_ended(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @suspended_days = @subscription&.feature_value(:suspended_days)&.to_i || 3
    @subject = %(#{Rails.application.credentials.global[:service_name]} Business Plan activation failed. All content is removed.)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 15 Payment not successful, Grace period started
  def grace_started_payment_failed(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @grace_period_days = @subscription.feature_value(:grace_days).to_i

    @subject = I18n.t('mailers.service_subscriptions_mailer.grace_started_payment_failed.subject', platform_name: Rails.application.credentials.global[:service_name])
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 19 Grace period end, Suspended start
  def suspended_started(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @plan = @subscription.stripe_plan
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @suspended_days = @subscription&.feature_value(:suspended_days)&.to_i || 3
    @subject = I18n.t('mailers.service_subscriptions_mailer.suspended_started.subject')
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, subject: @subject)
  end

  # 20 Suspended period ends, deactivated
  def deactivated(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @user = @subscription.user
    @subject = I18n.t('mailers.service_subscriptions_mailer.deactivated.subject', platform_name: Rails.application.credentials.global[:service_name])

    platform_admins = Admin.where(receive_owner_mailing: true).pluck(:email)
    platform_owners = User.where(platform_role: :platform_owner).pluck(:email)
    cc_emails = (platform_admins + platform_owners).compact.uniq

    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail(to: @user.email, bcc: cc_emails, subject: @subject)
  end

  def notify_platform_owner(subscription_id)
    @subscription = StripeDb::ServiceSubscription.find(subscription_id)
    @interval_type = @subscription.stripe_plan.interval_type
    @plan_package = @subscription.plan_package
    @user = @subscription.user
    @subject = I18n.t('mailers.service_subscriptions_mailer.notify_platform_owner.subject', platform_name: Rails.application.credentials.global[:service_name])

    platform_admins = Admin.where(receive_owner_mailing: true).pluck(:email)
    platform_owners = User.where(platform_role: :platform_owner).pluck(:email)
    emails = (platform_admins + platform_owners).compact.uniq.join(',')

    mail(to: emails, subject: @subject)
  end
end
