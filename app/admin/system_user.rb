# frozen_string_literal: true

ActiveAdmin.register SystemUser do
  menu parent: 'Admin settings'

  permit_params :user_id

  filter :user_id, label: 'User ID'
  filter :created_at

  form do |f|
    f.inputs do
      f.input :user_id
    end

    f.actions
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
