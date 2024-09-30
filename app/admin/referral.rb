# frozen_string_literal: true

ActiveAdmin.register Referral do
  menu parent: 'System'

  actions :all

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
