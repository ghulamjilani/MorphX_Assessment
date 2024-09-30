# frozen_string_literal: true

ActiveAdmin.register ::Comment, as: 'Comment' do
  menu parent: 'System'
  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
