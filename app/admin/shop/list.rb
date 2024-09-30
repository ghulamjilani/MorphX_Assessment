# frozen_string_literal: true

ActiveAdmin.register Shop::List, as: 'List' do
  menu parent: 'Shop'

  actions :all

  filter :organization_id, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization Name'
  filter :name
  filter :description
  filter :created_at

  index do
    selectable_column
    column :id
    column :name
    column :organization
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
