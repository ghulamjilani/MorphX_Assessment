# frozen_string_literal: true

ActiveAdmin.register AccessManagement::GroupsCredential do
  menu parent: 'Access Management'

  actions :all

  index do
    selectable_column
    id_column
    column 'Role', &:group
    column :credential
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
