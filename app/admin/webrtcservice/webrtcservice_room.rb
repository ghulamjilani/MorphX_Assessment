# frozen_string_literal: true

ActiveAdmin.register WebrtcserviceRoom do
  menu parent: 'Webrtcservice', label: 'Webrtcservice Room'
  actions :all

  filter :id
  filter :session_id
  filter :sid
  filter :unique_name
  filter :record_enabled
  filter :max_participants
  filter :status
  filter :ended_at
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :session_id
    column :session
    column :room
    column :sid
    column :unique_name
    column :record_enabled
    column :max_participants
    column :status
    column :ended_at
    column :created_at
    column :updated_at
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
