# frozen_string_literal: true

ActiveAdmin.register ::PageBuilder::SystemTemplate do
  menu parent: 'Customization'

  actions :all

  filter :id
  filter :name
  filter :created_at
  filter :updated_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
