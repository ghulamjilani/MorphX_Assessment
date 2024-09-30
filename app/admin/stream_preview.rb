# frozen_string_literal: true

ActiveAdmin.register StreamPreview do
  menu parent: 'Ffmpegservice'

  filter :id
  filter :user_id
  filter :organization_id
  filter :ffmpegservice_account_id
  filter :created_at
  filter :updated_at
  filter :stopped_at

  index do
    selectable_column
    column :id
    column :user, sortable: :user_id
    column :organization, sortable: :organization_id
    column :ffmpegservice_account, sortable: :ffmpegservice_account_id
    column :created_at
    column :end_at, &:end_at
    column :stopped_at

    actions
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
