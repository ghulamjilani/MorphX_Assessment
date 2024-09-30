# frozen_string_literal: true

ActiveAdmin.register_page 'Mailing' do
  menu parent: 'Admin Settings'

  page_action :send_bulk, method: :post do
    emails = params[:emails_list].split(/[\n,\s]+/).filter { |e| e =~ URI::MailTo::EMAIL_REGEXP }
    subject = params[:subject]
    message = params[:message]
    Mailer.bulk_custom_email(emails: emails, content: message, subject: subject).deliver_later
    redirect_to service_admin_panel_mailing_path, notice: 'Email will be sent in a few seconds'
  end

  content do
    columns do
      column do
        panel 'Bulk email' do
          form decorate: true, action: 'mailing/send_bulk', method: :post do |f|
            f.input type: :hidden, name: :authenticity_token
            table do
              columns do
                column do
                  f.label 'Subject', for: :subject, class: 'label'
                  para do
                    f.input id: :subject, name: :subject, size: 40
                  end
                  f.label 'Message', for: :message, class: 'label'
                  para do
                    f.textarea id: :message, name: :message, class: 'autogrow', rows: 10, cols: 20
                  end
                  f.label 'Emails, separated by coma or newline', for: :emails_list, class: 'label'
                  para do
                    f.textarea id: :emails_list, name: :emails_list, class: 'autogrow', rows: 10, cols: 20
                  end
                  para do
                    f.input :submit, type: :submit
                  end
                end
                column do
                  label 'Filter'
                  para { input id: :contact_filter, size: 40 }
                  label 'Users'
                  para do
                    select id: :contacts_list, multiple: true, size: 30, style: 'min-width: 400px;' do
                      User.all.order('first_name').each do |u|
                        option "#{u.full_name} <#{u.email}>", value: u.email
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
