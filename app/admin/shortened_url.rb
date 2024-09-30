# frozen_string_literal: true

ActiveAdmin.register Shortener::ShortenedUrl do
  menu parent: 'Admin settings'

  form do |f|
    f.inputs do
      f.input :owner_type
      f.input :url, as: :text, html: { row: 5 }
      f.input :unique_key
      f.input :category
      f.input :expires_at, as: :datepicker
    end
    f.actions
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
