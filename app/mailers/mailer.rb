# frozen_string_literal: true

class Mailer < ApplicationMailer
  include ActionView::Helpers::TextHelper # for simple_format
  include ActionView::Helpers::UrlHelper
  include Devise::Mailers::Helpers

  def lets_talk(params)
    @params = params
    @request_uuid = SecureRandom.hex(8)
    mail(
      to: Rails.application.credentials.global[:support_mail],
      bcc: supports.join(','),
      reply_to: params[:email],
      subject: "Customer inquiry on #{Rails.application.credentials.global[:service_name]} ##{@request_uuid}"
    )
  end

  def system_parameter_changed(system_parameter)
    @system_parameter = system_parameter

    mail(
      to: owners.join(','),
      bcc: admins.join(','),
      subject: "#{@system_parameter.key} sys param has been changed on #{Rails.env}"
    )
  end

  def social_user_welcome(user_id)
    @user = User.find(user_id)

    @subject = I18n.t('mailers.dashboard.subject', service_name: Rails.application.credentials.global[:service_name])
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    if @user.email.present?

      mail to: @user.email,
           subject: @subject,
           template_path: 'mailboxer/notification_mailer',
           template_name: 'new_notification_email'
    end
  end

  def new_paypal_donation(paypal_donation_id)
    @paypal_donation = PaypalDonation.find(paypal_donation_id)

    mail(
      to: admins.join(','),
      bcc: csr_recipient_emails.join(','),
      subject: "[#{Rails.env}] New paypal donation update"
    )
  end

  def user_signed_up(user_id)
    @user = User.find(user_id)

    if Rails.env.production? || Rails.env.test? || Rails.env.development?
      mail(
        to: csr_recipient_emails.first,
        bcc: csr_recipient_emails.drop(1).join(','),
        subject: "[#{Rails.env}]New registered user"
      )
    end
  end

  def becoming_a_presenter_reached_step(user_id, step_name)
    @user         = User.find(user_id)
    @presenter    = @user.presenter

    @step = case step_name
            when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1
              'user profile'
            when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2
              'business profile'
            when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
              'channel creation'
            else
              raise ArgumentError, "can not interpret: #{step_name}"
            end

    mail(
      to: csr_recipient_emails.first,
      bcc: csr_recipient_emails.drop(1).join(','),
      subject: "[Become a presenter]#{@user.public_display_name} reached *#{@step}* step and stopped"
    )
  end

  def welcome_stopped_during_becoming_a_presenter(user_id)
    @user = User.find(user_id)

    @complete_presenter_profile_url = wizard_v2_url

    @subject = I18n.t('mailers.mailer.welcome_stopped_during_becoming_a_presenter.subject',
                      service_name: Rails.application.credentials.global[:service_name])

    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: nil,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         bcc: admins.join(','),
         reply_to: admins.join(','),
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def vod_didnt_became_available_on_time(abstract_session)
    @abstract_session = abstract_session

    mail(
      to: admins.join(','),
      subject: "[#{Rails.env.upcase}] #{@abstract_session.class.to_s.downcase} VOD for #{@abstract_session.title} didnt became available in a timely manner. Please resolve this issue"
    )
  end

  def vod_became_available_for_organizer(session_id)
    @session = Session.find(session_id)
    @user    = @session.organizer

    @subject = I18n.t('mailer.vod_became_available_for_organizer.subject', title: @session.title)
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

  def vod_just_became_available_for_purchase(user_id, abstract_session)
    @user                  = User.find(user_id)
    @abstract_session      = abstract_session
    abstract_session_title = @abstract_session.title

    @subject = I18n.t('mailer.vod_just_became_available_for_purchase.subject',
                      abstract_session_title: abstract_session_title)
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

  def locked_presenter_balance(presenter_id, admin_email)
    @presenter = Presenter.find(presenter_id)

    mail(
      to: admin_email,
      subject: "#{@presenter.user.public_display_name} went into negative balance and his presenter account is locked now"
    )
  end

  def pending_refund_caused_by_reason_other_than_updated_start_at(pending_refund_id)
    @pending_refund = PendingRefund.find(pending_refund_id)
    @user           = @pending_refund.user
    @channel = @pending_refund.payment_transaction.purchased_item.try(:channel)
    @direct_from_name = @channel.try(:title)

    @subject = 'Please select your preferred refund method'
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

  def pending_refund_caused_by_updated_start_at(pending_refund_id, model)
    unless [
      SessionParticipation,
      SessionCoPresentership,
      Livestreamer
    ].include?(model.class)
      raise "can not interpret #{model.inspect}"
    end

    @pending_refund = PendingRefund.find(pending_refund_id)
    @user           = @pending_refund.user
    @model          = model

    @subject = 'Session Start Time has changed'
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

  def share_via_email(email, message, subject)
    @content = message.html_safe

    mail(to: email,
         subject: subject,
         template_path: 'mailer') do |format|
      format.html { render 'email_general', layout: 'email' }
    end
  end

  def share_model_via_email(email, model)
    subject = 'Share via email'

    case model.class.name
    when 'User'
      user = model
      name = model.display_name
      user_link = link_to(user.display_name, spa_user_url(user.friendly_id))
      model_link = user_link
    when 'Channel'
      user = model.user
      name = model.title
      user_link = link_to(user.display_name, spa_channel_url(model.slug, user_modal: user.id))
      model_link = link_to(name, spa_channel_url(model.slug))
    when 'Recording'
      user = model.channel.user
      name = model.title
      user_link = link_to(user.display_name, spa_channel_url(model.channel.slug, user_modal: user.id))
      model_link = link_to(name, model.absolute_path)
    else
      user = model.user
      name = model.title
      user_link = link_to(user.display_name, spa_channel_url(model.channel.slug, user_modal: user.id))
      model_link = link_to(name, model.absolute_path)
    end

    message = "Hi, Check out #{user_link} #{model.class.name.downcase} on #{Rails.application.credentials.global[:service_name]}! #{model_link}"

    @content = message.html_safe

    mail(
      to: email,
      subject: subject,
      template_path: 'mailer'
    ) do |format|
      format.html { render 'email_general', layout: 'email' }
    end
  end

  def money_refund_receipt(user_id, log_transaction_id)
    @user = User.find(user_id)

    @log_transaction = LogTransaction.find(log_transaction_id)
    @payment_transaction = @log_transaction.payment_transaction

    @subject = 'Refund receipt'
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

  # https://github.com/plataformatec/devise/blob/master/app/mailers/devise/mailer.rb
  def confirmation_instructions(record, token, opts = {})
    @token      = token
    @scope_name = Devise::Mapping.find_scope!(record)
    @resource   = record
    @user       = record

    if Rails.env.development? || Rails.env.test?
      @subject = 'Please Confirm Your Email'
      @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                           subject: @subject,
                                                                           sender: nil,
                                                                           body: render_to_string(__method__,
                                                                                                  layout: false))

      opts[:template_path] = 'mailboxer/notification_mailer'
      opts[:template_name] = 'new_notification_email'
    end

    opts[:delivery_method_options] = enabled_smtp_options

    devise_mail(record, :confirmation_instructions, opts)
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    opts[:delivery_method_options] = enabled_smtp_options

    devise_mail(record, :reset_password_instructions, opts)
  end

  def invitation_instructions(record, token, opts = {})
    @token      = token
    @invited_by = record.invited_by

    raise '@invited_by has to be present' if @invited_by.blank?
    raise '@invited_by has to be of User kind' unless @invited_by.is_a?(User)

    action_and_template_name = :invitation_instructions_for_referred_friend

    if opts[:preview_only]
      if opts[:current_user]
        @invited_by = opts[:current_user]
      end
      @accept_url = ''
    else
      @accept_url = accept_user_invitation_url(invitation_token: (@token or raise 'missing @token'))
    end

    devise_mail(record, action_and_template_name, opts)
  end

  def ban_user(room_member_id)
    room_member = RoomMember.find(room_member_id)
    raise 'mail must not be sent to guest' unless room_member.user

    @user                  = room_member.user
    @abstract_session      = room_member.room.abstract_session
    @reason                = room_member.ban_reason.name
    @abstract_session_link = %(<a href = "#{@abstract_session.absolute_path(UTM.build_params(utm_content: @user.utm_content_value))}">#{@abstract_session.always_present_title}</a>)

    @subject = I18n.t("mailer.banned.#{@abstract_session.class.to_s.downcase}.subject",
                      name: @abstract_session.always_present_title)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @abstract_session.organizer,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def unban_user(room_member_id)
    room_member = RoomMember.find(room_member_id)
    raise 'mail must not be sent to guest' unless room_member.user

    @user                  = room_member.user
    @abstract_session      = room_member.room.abstract_session
    @abstract_session_link = %(<a href="#{@abstract_session.absolute_path(UTM.build_params(utm_content: @user.utm_content_value))}">#{@abstract_session.always_present_title}</a>)

    @subject = I18n.t("mailer.unbanned.#{@abstract_session.class.to_s.downcase}.subject",
                      name: @abstract_session.always_present_title)
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @abstract_session.organizer,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def twitter_widget_create_failed(session_id)
    @session = Session.find(session_id)
    mail(
      to: admins.join(','),
      subject: "[#{Rails.env}] Twitter widget ##{@session.twitter_feed_title} creation failed"
    )
  end

  def time_to_service(from_user_id:, email:, user_name: nil, content: nil)
    @from_user = begin
      User.find from_user_id
    rescue StandardError
      nil
    end
    @email = email
    @subject = I18n.t('mailers.mailer.time_to_service.subject',
                      service_name: Rails.application.credentials.global[:service_name])
    @user_name = user_name
    @content = content
    mail(
      to: @email,
      subject: @subject,
      delivery_method_options: enabled_smtp_options,
      template_path: 'mailer',
      template_name: 'time_to_service'
    ) do |format|
      format.html { render layout: 'email2' }
    end
  end

  def custom_email(email:, content:, subject:, replacements: {}, template: 'email_general', layout: 'email', title_text: '')
    @title_text = title_text
    @content = content
    @replacements = replacements
    mail(to: email,
         subject: subject,
         delivery_method_options: enabled_smtp_options,
         template_path: 'mailer') do |format|
      format.html { render template, layout: layout }
    end
  end

  def bulk_custom_email(emails:, content:, subject:, replacements: {}, template: 'email_general', layout: 'email')
    @content = content
    email = emails.shift
    @replacements = replacements
    mail(to: email,
         subject: subject,
         bcc: emails,
         template_path: 'mailer') do |format|
      format.html { render template, layout: layout }
    end
  end

  private

  def admins
    @admins ||= Admin.where(receive_admin_mailing: true).pluck(:email)
  end

  def owners
    @owners ||= Admin.where(receive_owner_mailing: true).pluck(:email)
  end

  def supports
    @supports ||= Admin.where(receive_support_mailing: true).pluck(:email)
  end
end
