# frozen_string_literal: true

class FreeSubscriptionsMailer < ApplicationMailer
  include Devise::Mailers::Helpers
  layout 'email'

  def invite(id)
    @free_subscription = FreeSubscription.joins(:user).find(id)
    @invited_user = @free_subscription.user
    @invited_user_name = "#{@invited_user.first_name} #{@invited_user.last_name}".presence || @invited_user.email
    @channel = @free_subscription.channel
    @direct_from_name = @channel.title
    @user = @free_subscription.channel.organization.user
    @btn_color = SystemTheme.find_by(is_default: true)&.system_theme_variables&.find_by(property: :btn__main)&.value || '#f23535'
    @host_name = Rails.application.credentials.global[:host]
    @host_url = "#{ENV['PROTOCOL']}#{@host_name}"

    if @invited_user.invited_by == @user && @invited_user.sign_in_count.zero?
      @invited_user.send(:generate_invitation_token!)
      @accept_url = accept_user_invitation_url(invitation_token: @invited_user.raw_invitation_token,
                                               return_to_after_connecting_account: @channel.absolute_path,
                                               redirect_to: @channel.absolute_path)
    else
      @accept_url = @channel.absolute_path
    end

    @subject = I18n.t('mailers.free_subscriptions_mailer.invite.subject', channel_title: @channel.title, plan_name: @free_subscription.free_plan.name)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @invited_user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @invited_user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def going_to_be_finished(id)
    @free_subscription = FreeSubscription.joins(:user).find(id)
    @invited_user = @free_subscription.user
    @channel = @free_subscription.channel
    @user = @free_subscription.channel.organization.user
    @btn_color = SystemTheme.find_by(is_default: true)&.system_theme_variables&.find_by(property: :btn__main)&.value || '#f23535'
    @direct_from_name = @channel.title

    @subject = I18n.t('mailers.free_subscriptions_mailer.going_to_be_finished.subject', channel_title: @channel.title, plan_name: @free_subscription.free_plan.name)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @invited_user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @invited_user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def ended(id)
    @free_subscription = FreeSubscription.joins(:user).find(id)
    @invited_user = @free_subscription.user
    @invited_user_name = "#{@invited_user.first_name} #{@invited_user.last_name}".presence || @invited_user.email
    @channel = @free_subscription.channel
    @user = @free_subscription.channel.organization.user
    @btn_color = SystemTheme.find_by(is_default: true)&.system_theme_variables&.find_by(property: :btn__main)&.value || '#f23535'

    @subject = I18n.t('mailers.free_subscriptions_mailer.ended.subject', channel_title: @channel.title, plan_name: @free_subscription.free_plan.name)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @invited_user,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail to: @invited_user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end
end
