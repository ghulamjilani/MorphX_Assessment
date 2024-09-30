# frozen_string_literal: true

ActiveAdmin.register ZoomMeeting do
  menu parent: 'Sessions'

  index do
    selectable_column
    id_column
    column :session
    column :meeting_id
    column :updated_at
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
