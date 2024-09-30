# frozen_string_literal: true

except_values = Rails.env.production? ? %i[new create edit destroy] : %i[new create edit]
ActiveAdmin.register Identity do
  menu parent: 'User'

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :provider
  filter :created_at, as: :date_range

  actions :all, except: except_values
  form do |f|
    f.inputs do
      f.input :user
      f.input :uid
      f.input :provider
      f.input :token
    end
    f.actions
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
