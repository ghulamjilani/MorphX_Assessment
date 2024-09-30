# frozen_string_literal: true

class Immerss::MultiFormatMailer < Immerss::AbstractMultiFormatMailer
  def follow_me(user, follower)
    @user = @recipient_user = user
    @follower = @sender = follower
    @subject  = 'You have a new follower!'

    respond_to(__method__) do |format|
      format.web do
        render_without_layout("app/views/multi_format_mailer/#{__method__}_web.html.erb")
      end

      format.email do
        token            = Tldr::TokenGenerator.new(user.id, __method__).token
        @unsubscribe_url = Rails.application.class.routes.url_helpers.preview_unsubscribe_url(token)

        @receiving_mail_because_description = I18n.t('mailer.footer.follow_me.receiving_mail_because_description')
        @prefer_not_to_receive_description  = I18n.t('mailer.footer.follow_me.prefer_not_to_receive_description')

        render_with_layout("multi_format_mailer/#{__method__}_email", locals: {
                             :@user => @user,
                             :@recipient_user => @recipient_user,
                             :@follower => @follower,
                             :@sender => @sender,
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
end
