# frozen_string_literal: true

module Immerss::ActsAsAbstractSessionMultiFormatMailer
  include MailerHelper
  extend ActiveSupport::Concern

  def model_name
    self.class.to_s.gsub('Immerss::', '').gsub('MultiFormatMailer', '').downcase
  end
  private :model_name

  def model_class
    self.class.to_s.gsub('Immerss::', '').gsub('MultiFormatMailer', '').constantize
  end
  private :model_class

  included do
    define_method "user_accepted_your_#{to_s.gsub('Immerss::', '').gsub('MultiFormatMailer',
                                                                        '').downcase}_invitation" do |session_id, user_id|
      @sender = @user = User.find(user_id)

      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      @recipient_user = model.organizer

      @subject = 'Your invitation was accepted'

      respond_to(__method__) do |format|
        format.web do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}_web.html.erb")
        end
        format.email do
          token            = Tldr::TokenGenerator.new(@recipient_user.id,
                                                      :user_accepted_or_rejected_your_invitation).token
          @unsubscribe_url = Rails.application.class.routes.url_helpers.preview_unsubscribe_url(token)

          @receiving_mail_because_description = I18n.t('mailer.footer.user_accepted_or_rejected_your_invitation.receiving_mail_because_description')
          @prefer_not_to_receive_description  = I18n.t('mailer.footer.user_accepted_or_rejected_your_invitation.prefer_not_to_receive_description')

          render_with_layout("#{model_name}_multi_format_mailer/#{__method__}_email", locals: {
                               :@sender => @sender,
                               :@user => @user,
                               :@recipient_user => @recipient_user,
                               "@#{model_name}".to_sym => model,
                               :@subject => @subject,
                               :@unsubscribe_url => @unsubscribe_url,
                               :@receiving_mail_because_description => @receiving_mail_because_description,
                               :@prefer_not_to_receive_description => @prefer_not_to_receive_description
                             })
        end
        format
      end
      self
    end

    define_method "user_rejected_your_#{to_s.gsub('Immerss::', '').gsub('MultiFormatMailer',
                                                                        '').downcase}_invitation" do |session_id, user_id|
      @sender = @user = User.find(user_id)

      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      @recipient_user = model.organizer

      @subject = 'Your invitation was declined'

      respond_to(__method__) do |format|
        format.web do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}_web.html.erb")
        end
        format.email do
          token            = Tldr::TokenGenerator.new(@recipient_user.id,
                                                      :user_accepted_or_rejected_your_invitation).token
          @unsubscribe_url = Rails.application.class.routes.url_helpers.preview_unsubscribe_url(token)

          @receiving_mail_because_description = I18n.t('mailer.footer.user_accepted_or_rejected_your_invitation.receiving_mail_because_description')
          @prefer_not_to_receive_description  = I18n.t('mailer.footer.user_accepted_or_rejected_your_invitation.prefer_not_to_receive_description')

          render_with_layout("#{model_name}_multi_format_mailer/#{__method__}_email", locals: {
                               :@sender => @sender,
                               :@user => @user,
                               :@recipient_user => @recipient_user,
                               "@#{model_name}".to_sym => model,
                               :@subject => @subject,
                               :@unsubscribe_url => @unsubscribe_url,
                               :@receiving_mail_because_description => @receiving_mail_because_description,
                               :@prefer_not_to_receive_description => @prefer_not_to_receive_description
                             })
        end
        format
      end
      self
    end

    define_method 'participant_invited_to_abstract_session' do |session_id, participant_id|
      @user = @recipient_user = Participant.find(participant_id).user

      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      @sender = model.organizer
      @subject = "New #{model.class} Invitation from #{model.organizer.public_display_name}"

      @follow_link_url = if @user.can_receive_abstract_session_invitation_without_invitation_token?
                           model.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))
                         else
                           Rails.application.class.routes.url_helpers.accept_user_invitation_url(invitation_token: generate_user_invitation_token_and_return!,
                                                                                                 return_to_after_connecting_account: model.absolute_path)
                         end

      respond_to(__method__) do |format|
        format.web do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}_web.html.erb")
        end
        format.email do
          token            = Tldr::TokenGenerator.new(@user.id, :participant_invited_to_abstract_session).token
          @unsubscribe_url = Rails.application.class.routes.url_helpers.preview_unsubscribe_url(token)

          @receiving_mail_because_description = I18n.t('mailer.footer.you_invited.receiving_mail_because_description')
          @prefer_not_to_receive_description  = I18n.t('mailer.footer.you_invited.prefer_not_to_receive_description')
          render_with_layout("#{model_name}_multi_format_mailer/#{__method__}_email", locals: {
                               :@user => @user,
                               :@recipient_user => @recipient_user,
                               "@#{model_name}".to_sym => model,
                               :@sender => @sender,
                               :@subject => @subject,
                               :@follow_link_url => @follow_link_url,
                               :@unsubscribe_url => @unsubscribe_url,
                               :@receiving_mail_because_description => @receiving_mail_because_description,
                               :@prefer_not_to_receive_description => @prefer_not_to_receive_description
                             })
        end
        format.sms do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}.sms.html.erb")
        end
        format
      end
      self
    end

    define_method 'start_reminder' do |session_id, user_id|
      @sender = nil # TODO: or organizer?

      @user = @recipient_user = User.find(user_id)
      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      if model.is_a?(Session)
        @url = model.absolute_path
        title = model.always_present_title
      else
        raise ArgumentError
      end

      @subject = "#{title} be starting soon!"

      respond_to(__method__) do |format|
        format.web do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}_web.html.erb")
        end
        format.email do
          render_with_layout("#{model_name}_multi_format_mailer/#{__method__}_email", locals: {
                               :@sender => @sender,
                               :@user => @user,
                               :@recipient_user => @recipient_user,
                               "@#{model_name}".to_sym => model,
                               :@url => @url,
                               :@subject => @subject
                             })
        end
        format.sms do
          render_without_layout("app/views/#{model_name}_multi_format_mailer/#{__method__}.sms.html.erb")
        end
        format
      end
      self
    end
  end
end
