# frozen_string_literal: true

ActiveAdmin.register ReferralCode do
  menu parent: 'System'

  actions :all, except: %i[new create edit update destroy]
  form do |f|
    f.inputs do
      f.input :user
      f.input :code
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
