# frozen_string_literal: true

class SessionMailer < ApplicationMailer
  include MailerConcerns::ActsAsAbstractSessionMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def free_session_was_approved_automatically(session_id, reason_type)
    @session     = Session.find(session_id)
    @reason_type = reason_type

    if Rails.env.production? || Rails.env.test? || Rails.env.development?
      mail(
        to: csr_recipient_emails.first,
        bcc: csr_recipient_emails.drop(1).join(','),
        subject: "[#{Rails.env}]New private free session approved automatically for #{@session.organizer.public_display_name}"
      )
    end
  end

  def pending_requested_free_session_appeared(session_id)
    @session = Session.find(session_id)

    if Rails.env.production? || Rails.env.test? || Rails.env.development?
      mail(
        to: csr_recipient_emails.first,
        bcc: csr_recipient_emails.drop(1).join(','),
        subject: "[#{Rails.env}]New pending requested free session"
      )
    end
  end

  def requested_free_session_just_got_granted(session_id)
    @session = Session.find(session_id)
    @user    = @session.channel.organizer # session's channel owner

    @subject = %(Requested free session #{@session.always_present_title} just got approved)
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

  def requested_free_session_submitted_for_review(session_id)
    @session = Session.find(session_id)
    @user    = @session.channel.organizer # session's channel owner

    @subject = %(Requested free session #{@session.always_present_title} is currently under review)
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

  def you_obtained_recorded_access(session_id, user_id, payment_transaction_id)
    @user = User.find(user_id)
    @session = Session.find(session_id)

    @payment_transaction = payment_transaction_id ? PaymentTransaction.find(payment_transaction_id) : nil

    @subject = 'Thank you for purchasing video on-demand'
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

  def requested_free_session_just_got_rejected(session_id)
    @session = Session.find(session_id)
    @user    = @session.channel.organizer # session's channel owner

    @subject = %(Requested free session #{@session.always_present_title} just got declined)
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

  def free_abstract_session_notify_about_changed_start_at(session_id, participant_or_presenter)
    @model   = participant_or_presenter
    @session = Session.find(session_id)
    @user    = participant_or_presenter.user

    @subject = 'Session Start Time has changed!'
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

  def you_as_co_presenter_accepted_session_invitation(session_id, user_id)
    @user = User.find(user_id)

    @session = Session.find(session_id)

    @subject = 'Thank you for accepting the invitation'
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

  def publish_reminder(session_id)
    model = Session.find(session_id)
    @session = model

    @user = model.presenter.user

    @url = model.absolute_path
    title = model.title || model.always_present_title

    @subject = "Reminder to publish #{title}"
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

  def published_session_from_user_you_follow(session_id, user_id)
    @session = Session.find(session_id)
    @user = User.find(user_id)
    @date = @session.start_now ? 'happening now' : "scheduled for #{@session.start_at.in_time_zone(@user.timezone).strftime('%I:%M %p on %b %e')}"

    @subject = I18n.t('mailer.published_session_from_user_you_follow.subject',
                      user_name: @session.organizer.public_display_name)
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

  def published_session_from_channel_you_follow(session_id, user_id)
    @session      = Session.find(session_id)
    @user         = User.find(user_id)
    @date = @session.start_now ? 'happening now' : "scheduled for #{@session.start_at.in_time_zone(@user.timezone).strftime('%I:%M %p on %b %e')}"

    @subject = I18n.t('mailer.published_session_from_user_you_follow.subject',
                      user_name: @session.organizer.public_display_name)
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

  def hurry_up_to_purchase_slot(session_id, user_id)
    @user    = User.find(user_id)
    @session = Session.find(session_id)

    @subject = 'Session you wanted freed up. Hurry up and book it!'
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

  def co_presenter_invited_to_session(session_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @session = Session.find(session_id)

    @subject = I18n.t('mailers.session_mailer.co_presenter_invited_to_session.subject',
                      name: @session.organizer.public_display_name,
                      service_name: Rails.application.credentials.global[:service_name])

    @follow_link_url = if @user.can_receive_abstract_session_invitation_without_invitation_token?
                         @session.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))
                       else
                         accept_user_invitation_url(invitation_token: generate_user_invitation_token_and_return!,
                                                    return_to_after_connecting_account: @session.absolute_path)
                       end

    ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                         subject: @subject,
                                                         sender: @session.organizer,
                                                         body: render_to_string("#{__method__}_web", layout: false))

    mail to: @user.email,
         subject: @subject,
         template_name: "#{__method__}_email"
  end

  def co_presenter_rejected_from_session(session_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @session = Session.find(session_id)

    @subject = " #{I18n.t('mailers.session_mailer.co_presenter_rejected_from_session.subject', creator: I18n.t('dictionary.creator'))} #{@session.organizer.public_display_name}"
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

  def participant_rejected_from_session(session_id, participant_id)
    @user    = Participant.find(participant_id).user
    @session = Session.find(session_id)
    @direct_from_name = @session.channel.title

    @subject = "You have been removed as a participant by #{@session.organizer.public_display_name}"
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

  def presenter_assigned_to_session(session_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @session = Session.find(session_id)
    @organizer = @session.channel.organizer

    @subject = I18n.t('mailers.session_mailer.presenter_assigned_to_session.subject',
                      service_name: Rails.application.credentials.global[:service_name])

    @follow_link_url = @session.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))

    ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                         subject: @subject,
                                                         sender: @organizer,
                                                         body: render_to_string("#{__method__}_web", layout: false))

    mail to: @user.email,
         subject: @subject,
         template_name: "#{__method__}_email"
  end

  def presenter_unassigned_from_session(session_id, presenter_id)
    @user    = Presenter.find(presenter_id).user
    @session = Session.find(session_id)
    @organizer = @session.channel.organizer

    @subject = I18n.t('mailers.session_mailer.presenter_unassigned_from_session.subject',
                      name: @organizer.public_display_name,
                      service_name: Rails.application.credentials.global[:service_name])

    @follow_link_url = @session.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))

    ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                         subject: @subject,
                                                         sender: @organizer,
                                                         body: render_to_string("#{__method__}_web", layout: false))

    mail to: @user.email,
         subject: @subject,
         template_name: "#{__method__}_email"
  end
end
