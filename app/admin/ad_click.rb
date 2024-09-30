# frozen_string_literal: true

ActiveAdmin.register ::AdClick do
  menu parent: 'Advertisement'

  actions :all

  filter :id
  filter :user_id, label: 'User ID'
  filter :pb_ad_banner_id, label: 'Ad Banner ID'
  filter :created_at

  index do
    selectable_column
    column :id
    column :user
    column :ad_banner
    column :created_at
    actions
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
