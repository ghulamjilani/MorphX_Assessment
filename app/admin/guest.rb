# frozen_string_literal: true

ActiveAdmin.register Guest do
  menu parent: 'User'

  actions :all

  filter :id
  filter :visitor_id
  filter :public_display_name
  filter :ip_address
  filter :user_agent
  filter :created_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
