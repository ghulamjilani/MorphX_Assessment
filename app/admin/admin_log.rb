# frozen_string_literal: true

ActiveAdmin.register AdminLog, as: 'Logs' do
  menu parent: 'Admin settings'

  index do
    selectable_column
    id_column
    column :admin
    column :loggable_type
    column 'Loggable id' do |object|
      raw(object.loggable_id)
    end
    column :loggable
    column :action
    column 'Created at' do |object|
      raw(object.created_at.localtime.strftime('%B %d, %Y %H:%M'))
    end
    column 'Differences' do |object|
      render 'admin_log', { object: object }
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
