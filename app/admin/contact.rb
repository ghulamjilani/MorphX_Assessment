# frozen_string_literal: true

ActiveAdmin.register Contact do
  menu parent: 'User'

  actions :all

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
