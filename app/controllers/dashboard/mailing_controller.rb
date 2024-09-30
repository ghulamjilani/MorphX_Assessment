# frozen_string_literal: true

class Dashboard::MailingController < Dashboard::ApplicationController
  respond_to :json

  def index
    respond_to do |format|
      format.html do
        @subject = "#{current_user.display_name} : #{I18n.t('mailers.dashboard.subject',
                                                            service_name: Rails.application.credentials.global[:service_name])}"
        @templates = Mailing::Template::BASIC
        set_email_preview
      end
      format.js
    end
  end

  def email_preview
    set_email_preview
    respond_to(&:js)
  end

  def send_time_to_service
    ids = params.fetch(:contacts, [])
    content = custom_content_param
    subject = params.fetch(:subject,
                           I18n.t('mailers.dashboard.subject',
                                  service_name: Rails.application.credentials.global[:service_name])).first(80)
    EmailJobs::SendTimeToServiceEmailJob.perform_async(current_user.id, ids, content, subject)
    redirect_to dashboard_mailing_index_path, notice: 'Emails will be sent soon!'
  end

  def send_email
    ids = params.fetch(:contacts, [])
    content = custom_content_param
    subject = params.fetch(:subject,
                           I18n.t('mailers.dashboard.subject',
                                  service_name: Rails.application.credentials.global[:service_name])).first(80)
    template = Mailing::Template::ALL.find { |t| t[:id] == params[:template] } || Mailing::Template::GENERAL
    EmailJobs::SendEmailJob.perform_async(current_user.id, ids, content, subject, template[:if], template[:layout])
    redirect_to dashboard_mailing_index_path, notice: 'Emails will be sent soon!'
  end

  private

  def set_email_preview
    service_link = "#{ENV['PROTOCOL']}#{Rails.application.credentials.global[:host]}"
    template = Mailing::Template::ALL.find { |t| t[:id] == params[:template] } || Mailing::Template::GENERAL
    @custom_content = custom_content_param.presence || I18n.t('mailers.dashboard.body',
                                                              service_link: service_link, service_name: Rails.application.credentials.global[:service_name]).html_safe
    doc = Nokogiri::HTML(Mailer.custom_email(email: 'user@example.com', content: @custom_content.html_safe,
                                             subject: @subject, template: template[:id], layout: template[:layout]).body.to_s)
    @email_preview = doc.at('body').inner_html
  end

  def custom_content_param
    @custom_content_param ||= params[:custom_content].to_s.strip.first(2000).html_safe
  end
end
