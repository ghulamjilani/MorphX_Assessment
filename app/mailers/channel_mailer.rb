# frozen_string_literal: true

class ChannelMailer < ApplicationMailer
  include Devise::Mailers::Helpers
  def presenter_invited(channel_id, presenter_id)
    @channel  = Channel.find(channel_id)
    @user     = Presenter.find(presenter_id).user
    @inviter  = @channel.organizer
    @subject = I18n.t('mailer.channel.invite_as_creator_subject', channel_name: @channel.title,
                                                                  service_name: Rails.application.credentials.global[:service_name])

    if @user.can_receive_abstract_session_invitation_without_invitation_token?
      @follow_link_url = @channel.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))
      @title_text = @subject
    else
      @follow_link_url = accept_user_invitation_url(invitation_token: generate_user_invitation_token_and_return!,
                                                    return_to_after_connecting_account: @channel.absolute_path)
      @title_text = I18n.t('mailers.channel.presenter_invited.title',
                           service_name: Rails.application.credentials.global[:service_name])
    end

    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @inviter,
                                                                         body: render_to_string("#{__method__}_web",
                                                                                                layout: false))

    mail(to: @user.email,
         subject: @subject,
         template_path: 'channel_mailer') do |format|
      format.html { render layout: 'email3' }
    end
  end

  def presenter_rejected(channel_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @channel = Channel.find(channel_id)
    @brand_url = @channel.organization&.absolute_path || @channel.organizer.absolute_path
    @brand_name = @channel.organization&.name || @channel.organizer.public_display_name
    @subject = I18n.t('mailer.channel.removed_as_creator_subject', brand_name: @brand_name,
                                                                   service_name: Rails.application.credentials.global[:service_name])
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @channel.organizer,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def presenter_accepted_your_invitation(channel_id, presenter_id)
    @user = Presenter.find(presenter_id).user
    @channel = Channel.find(channel_id)
    @channel_owner = @channel.organizer

    @subject = 'Your invitation was accepted'

    mail to: @channel_owner.email,
         subject: @subject,
         template_name: "#{__method__}_email"
  end

  def presenter_rejected_your_invitation(channel_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @channel = Channel.find(channel_id)
    @channel_owner = @channel.organizer

    @subject = 'Your invitation was declined'

    mail to: @channel_owner.email,
         subject: @subject,
         template_name: "#{__method__}_email"
  end

  def channel_rejected(channel_id)
    @channel = Channel.find(channel_id)
    @user    = @channel.organizer

    @subject = 'Your channel was not approved.'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))
    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def draft_channel_reminder(channel_id)
    @channel = Channel.find(channel_id)
    @user    = @channel.organizer

    @subject = "Are you ready to submit #{@channel.title} for review?"
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def notify_about_1st_published_session(channel_id, user_id)
    @channel = Channel.find(channel_id)
    @session = @channel.sessions.upcoming.published.first!
    @user    = User.find(user_id)

    title = @session.title || @session.always_present_title

    @subject = I18n.t('mailer.notify_about_1st_published_session.subject', session_title: title,
                                                                           service_name: Rails.application.credentials.global[:service_name])

    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @session.organizer,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def channel_approved(channel_id)
    @channel = Channel.find(channel_id)
    @user    = @channel.organizer

    @subject = 'Congratulations! Your channel has been approved.'
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def pending_channel_appeared(channel_id)
    @channel = Channel.find(channel_id)

    if Rails.env.production? || Rails.env.test? || Rails.env.development?
      mail(
        to: csr_recipient_emails.first,
        bcc: csr_recipient_emails.drop(1).join(','),
        subject: "[#{Rails.env}]Channel has been submitted for approval"
      )
    end
  end

  # for admins only
  def channel_updated(changed_attrs, channel, email)
    @changed_attrs = changed_attrs
    @channel       = channel

    mail(
      to: email,
      subject: 'Channel change notification'
    )
  end
end
