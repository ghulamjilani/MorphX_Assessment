# frozen_string_literal: true

ActiveAdmin.register View do
  menu parent: 'Analytics'

  actions :all

  filter :id
  filter :user_id
  filter :viewable_id
  filter :viewable_type
  filter :group_name
  filter :user_agent
  filter :request_id
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :viewable
    column :viewable_id
    column :viewable_type
    column :user_id
    column :ip_address
    column :group_name
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
