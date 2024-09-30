# frozen_string_literal: true

class CompanyMailer < ApplicationMailer
  include Devise::Mailers::Helpers

  def employee_invited(membership_id)
    @membership = OrganizationMembership.find(membership_id)
    @company    = @membership.organization
    @user       = @membership.user
    @direct_from_name = @company.name

    @follow_link_url = if @user.can_receive_abstract_session_invitation_without_invitation_token?
                         @company.absolute_path(UTM.build_params({ utm_content: @user.utm_content_value }))
                       else
                         accept_user_invitation_url(invitation_token: generate_user_invitation_token_and_return!,
                                                    return_to_after_connecting_account: @company.absolute_path)
                       end

    @subject = I18n.t('mailers.channel.employee_invited.subject',
                      role: @membership.role,
                      name: @company.name,
                      service_name: Rails.application.credentials.global[:service_name])

    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @company.user,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end

  def employee_rejected(user_id, company_id)
    @company = Organization.find(company_id)
    @user    = User.find(user_id)
    @direct_from_name = @company.name

    @subject = "You have been detached from the company #{@company.name}."
    @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                         subject: @subject,
                                                                         sender: @company.user,
                                                                         body: render_to_string(__method__,
                                                                                                layout: false))

    mail to: @user.email,
         subject: @subject,
         template_path: 'mailboxer/notification_mailer',
         template_name: 'new_notification_email'
  end
end
