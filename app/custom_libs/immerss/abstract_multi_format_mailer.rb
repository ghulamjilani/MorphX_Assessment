# frozen_string_literal: true

class DefaultFormatPolicy
  def web?(user, _method)
    user.receives_notification?("#{_method}_via_web")
  end

  def email?(user, _method)
    user.receives_notification?("#{_method}_via_email")
  end

  def sms?(user, _method)
    user.receives_notification?("#{_method}_via_sms")
  end
end

class Immerss::AbstractMultiFormatMailer
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TextHelper

  def initialize(format_policy_klass = DefaultFormatPolicy)
    @format_policy = format_policy_klass.to_s.constantize.new
  end

  def render_without_layout(template)
    template = File.read(template)
    ERB.new(template, trim_mode: '-').result(get_binding)
  end

  def render_with_layout(template, locals: {})
    ApplicationController.render(
      template: template,
      locals: locals,
      layout: 'layouts/email',
      format: :html
    )
  end

  def deliver
    if @email_result.present?
      ActionMailer::Base.mail(
        to: @recipient_user.email,
        content_type: 'text/html',
        subject: @subject,
        body: @email_result
      ).deliver_later
    end

    if @web_result.present?
      ::Immerss::Mailboxer::Notification.save_with_receipt(user: @recipient_user,
                                                           subject: @subject,
                                                           sender: @sender,
                                                           body: @web_result)
    end

    if @sms_result.present?
      sms_config = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :sms)
      if sms_config.blank? || !sms_config.is_a?(Hash) || sms_config[:account_sid].blank? || sms_config[:auth_token].blank? || sms_config[:phone_number].blank?
        Rails.logger.warn 'Webrtcservice Messaging service is not configured'
      elsif sms_config[:enabled].blank?
        Rails.logger.warn 'Webrtcservice Messaging service is disabled'
      elsif @recipient_user.user_account.blank?
        Rails.logger.warn "SMS phone number is not set #{@recipient_user.id}"
      elsif !@recipient_user.current_phone_is_approved?
        Rails.logger.warn "SMS phone number is not approved #{@recipient_user.id}"
      else
        # clean_sms_body = strip_tags(@body).tr("\n","")
        #=> "Congrats! Cario and Resistance Training was just purchased by Allison Allison and 3 other participants. Keep up the good work!"

        begin
          client = Webrtcservice::REST::Client.new sms_config[:account_sid], sms_config[:auth_token]
          # throws Webrtcservice::REST::RequestError: The 'To' number 380971126326 is not a valid phone number.
          message = client.messages.create(
            from: sms_config[:phone_number],
            to: "+#{@recipient_user.user_account.phone.delete('+')}",
            body: @sms_result
          )

          WebrtcserviceMessage.create!({
                                  user: @recipient_user,
                                  sid: message.sid,
                                  date_created: message.date_created,
                                  date_sent: message.date_sent,
                                  account_sid: message.account_sid,
                                  to: message.to,
                                  from: message.from,
                                  body: message.body,
                                  status: message.status,
                                  direction: message.direction,
                                  price: message.price,
                                  price_unit: message.price_unit,
                                  error_code: message.error_code,
                                  error_message: message.error_message,
                                  num_media: message.num_media,
                                  num_segments: message.num_segments,
                                  uri: message.uri
                                })
        rescue StandardError => e
          Airbrake.notify(e,
                          parameters: {
                            user_id: @recipient_user.id,
                            to: "+#{@recipient_user.user_account.phone.delete('+')}"
                          })
        end
      end
    end
  end

  private

  def get_binding
    binding # So that everything can be used in templates generated for the servers
  end

  def respond_to(_method)
    format = OpenStruct.new _method: _method, recipient_user: @recipient_user, format_policy: @format_policy
    def format.web
      if format_policy.web?(recipient_user, _method)
        self.web_result = yield
      end
    end

    def format.email
      if format_policy.email?(recipient_user, _method)
        self.email_result = yield
      end
    end

    def format.sms
      if format_policy.sms?(recipient_user, _method)
        self.sms_result = ActionView::Base.full_sanitizer.sanitize(yield).tr("\n", '')
      end
    end

    result = yield(format)
    unless result.is_a?(OpenStruct)
      raise ArgumentError 'OpenStruct(format) has to be returned from respond_to method'
    end

    @web_result = format.web_result
    @email_result = format.email_result
    @sms_result = format.sms_result

    result
  end
end
