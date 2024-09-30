# frozen_string_literal: true

class Immerss::SessionMultiFormatMailer < Immerss::AbstractMultiFormatMailer
  include Immerss::ActsAsAbstractSessionMultiFormatMailer

  def wishlist_session(follower_user_id, session_id)
    @follower = @sender = User.find(follower_user_id)
    @session  = Session.find(session_id)

    @user = @recipient_user = @session.presenter.user

    @subject = 'Customer added your session to a wish list'

    respond_to(__method__) do |format|
      format.web do
        render_without_layout("app/views/session_multi_format_mailer/#{__method__}_web.html.erb")
      end
      format.email do
        token            = Tldr::TokenGenerator.new(@user.id, __method__).token
        @unsubscribe_url = Rails.application.class.routes.url_helpers.preview_unsubscribe_url(token)

        @receiving_mail_because_description = I18n.t('mailer.footer.wishlist_session.receiving_mail_because_description')
        @prefer_not_to_receive_description  = I18n.t('mailer.footer.wishlist_session.prefer_not_to_receive_description')

        render_with_layout("session_multi_format_mailer/#{__method__}_email", locals: {
                             :@user => @user,
                             :@follower => @follower,
                             :@sender => @sender,
                             :@session => @session,
                             :@subject => @subject,
                             :@recipient_user => @recipient_user,
                             :@unsubscribe_url => @unsubscribe_url,
                             :@receiving_mail_because_description => @receiving_mail_because_description,
                             :@prefer_not_to_receive_description => @prefer_not_to_receive_description
                           })
      end
      format
    end
    self
  end

  def purchases_summary_for_organizer(session_id)
    @session = Session.find(session_id)
    @recipient_user = @session.organization.user
    @sender  = nil
    @subject = 'Purchases Overview'

    @last_immersive_purchaser_user  = @session.session_participations.last.try(:user)
    @last_livestream_purchaser_user = @session.livestreamers.last.try(:user)

    total_immersive_num = @session.session_participations.count
    total_livestream_num = @session.livestreamers.count

    if @last_immersive_purchaser_user.blank? && @last_livestream_purchaser_user.blank?
      raise ArgumentError, session_id
    end

    suffix = ''
    if @last_immersive_purchaser_user.present?
      suffix += 'was just purchased by '
      suffix += link_to(@last_immersive_purchaser_user.public_display_name,
                        @last_immersive_purchaser_user.absolute_path)

      unless (total_immersive_num - 1).zero?
        suffix += " and #{pluralize(total_immersive_num - 1, 'other participant')}"
      end
    end

    if @last_livestream_purchaser_user.present? && @last_immersive_purchaser_user.present?
      suffix += ' and Livestream was just purchased by '
      suffix += link_to(@last_livestream_purchaser_user.public_display_name,
                        @last_livestream_purchaser_user.absolute_path)

      unless (total_livestream_num - 1).zero?
        suffix += " and #{pluralize(total_livestream_num - 1, 'other participant')}"
      end
    end

    if @last_immersive_purchaser_user.blank? && @last_livestream_purchaser_user.present?
      suffix = 'Livestream was just purchased by '
      suffix += link_to(@last_livestream_purchaser_user.public_display_name,
                        @last_livestream_purchaser_user.absolute_path)
      unless (total_livestream_num - 1).zero?
        suffix += " and #{pluralize(total_livestream_num - 1, 'other participant')}"
      end
    end

    @body = "Congrats! #{link_to @session.title, @session.absolute_path} #{suffix}. \nKeep up the good work!"

    respond_to(__method__) do |format|
      format.web do
        render_without_layout("app/views/session_multi_format_mailer/#{__method__}_web.html.erb")
      end

      format.email do
        render_with_layout("session_multi_format_mailer/#{__method__}_email", locals: {
                             :@session => @session,
                             :@recipient_user => @recipient_user,
                             :@sender => @sender,
                             :@subject => @subject,
                             :@last_immersive_purchaser_user => @last_immersive_purchaser_user,
                             :@last_livestream_purchaser_user => @last_livestream_purchaser_user,
                             :@body => @body
                           })
      end

      format.sms do
        @body
      end

      format
    end
    self
  end

  def session_no_stream_stop_scheduled(session_id)
    @session = Session.find(session_id)
    @recipient_user = @session.presenter.user
    @sender  = nil
    @subject = I18n.t("custom_libs.immerss.session_multi_format_mailer.#{__method__}.subject", minutes_to_stop: 5)
    @body = I18n.t("custom_libs.immerss.session_multi_format_mailer.#{__method__}.body",
                   public_display_name: @recipient_user.public_display_name,
                   session_link: link_to(@session.title, @session.absolute_path),
                   minutes_to_stop: 5)

    respond_to(__method__) do |format|
      format.web do
        render_without_layout("app/views/session_multi_format_mailer/#{__method__}_email.html.erb")
      end

      format.email do
        render_with_layout("session_multi_format_mailer/#{__method__}_email", locals: { :@body => @body })
      end

      format.sms do
        @body
      end

      format
    end
    self
  end
end
