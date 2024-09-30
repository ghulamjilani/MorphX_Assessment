# frozen_string_literal: true

ActiveAdmin.register BanReason do
  menu parent: 'Admin settings'

  actions :all, except: [:destroy]
  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
