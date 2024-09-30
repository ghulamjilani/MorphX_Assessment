# frozen_string_literal: true

ActiveAdmin.register_page 'System Reports' do
  menu parent: 'Admin Settings'

  page_action :untracked_vod_report, method: :post do
    email = params[:email]
    EmailJobs::VodS3UntrackedObjectsReportJob.perform_async(email)
    redirect_to service_admin_panel_system_reports_path, notice: 'Report is being prepared and will be sent in a few minutes'
  end

  content do
    columns do
      column do
        panel 'Untracked VOD S3 objects report' do
          form decorate: true, action: 'system_reports/untracked_vod_report', method: :post do |f|
            f.input type: :hidden, name: :authenticity_token
            f.label 'Email', for: :email, class: 'label'
            para do
              f.input id: :email, name: :email, size: 40
            end
            para do
              f.input :submit, type: :submit, style: 'margin-top: 20px;'
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
