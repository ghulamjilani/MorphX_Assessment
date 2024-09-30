# frozen_string_literal: true

ActiveAdmin.register OrganizationCover do
  menu parent: 'Images'
  actions :all, except: %i[new create edit update destroy]

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
